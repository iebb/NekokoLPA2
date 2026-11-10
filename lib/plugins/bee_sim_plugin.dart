import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../adapter/ble/bee_sim_adapter.dart';
import '../adapter/euicc_adapter.dart';
import '../l10n/app_localizations.dart';
import '../models/euicc_profile.dart';
import '../utils/hex_utils.dart';
// import '../widgets/profiles_screen/action_button.dart';
import 'plugin_base.dart';

/// The BeeSIM firmware-update flow, as a reader action. The action is
/// commented out, so nothing starts the flow.
///
/// The action is only shown when the connected reader is a [BeeSimAdapter].
/// On tap the plugin opens a modal log dialog, asks the adapter for its
/// current firmware state, posts that state to BeeSIM's upgrade-check
/// endpoint, and — if the server returns pending rows — streams them back
/// onto the device one by one. The wire format and signing scheme mirror the
/// BeeSIM web BLE client.
class BeeSimPlugin extends ProfilePlugin {
  static final Logger _log = Logger('BeeSimPlugin');

  BeeSimPlugin({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  // Pinned constants from the BeeSIM web client. They are not secrets — the
  // upstream JS bundle ships them to every browser — but they DO have to stay
  // in sync with the server's expectation.
  static const _apiBase = 'https://api.beeesim.com';
  static const _signSecret = 'Hz3wU92K2ion6Kaq';
  static const _upgradeKey = 'BEESIM_FW_UPGRADE';

  final http.Client _httpClient;

  @override
  String get id => 'bee_sim';

  @override
  String get name => 'BeeSIM';

  @override
  bool isMatch(EuiccProfile profile) => false;

  // The firmware check is off, so no reader action is offered.
  // api.beeesim.com serves an expired certificate, and the rows it returns are
  // written to the reader with no signature check, so the request must not be
  // made over an unverified connection. To restore it, uncomment this override
  // and the action_button import, and drop the skips in
  // test/plugins/bee_sim_plugin_test.dart.
  //
  // @override
  // List<Widget> buildReaderActions(
  //   BuildContext context,
  //   ReaderActionContext actionContext,
  // ) {
  //   final adapter = actionContext.adapter;
  //   final source = actionContext.reader?.source;
  //   final beeAdapter = _resolveBeeAdapter(adapter, source);
  //   if (beeAdapter == null) return const <Widget>[];
  //   final l10n = AppLocalizations.of(context)!;
  //   return <Widget>[
  //     ActionButton(
  //       icon: Icons.memory,
  //       label: l10n.beeSimFirmwareAction,
  //       onPressed: () => _runFirmwareUpgrade(context, beeAdapter),
  //     ),
  //   ];
  // }

  // ignore: unused_element -- used by the commented-out reader action above
  BeeSimAdapter? _resolveBeeAdapter(Adapter adapter, Object? source) {
    if (adapter is BeeSimAdapter) return adapter;
    if (source is BeeSimAdapter) return source;
    return null;
  }

  // ignore: unused_element -- used by the commented-out reader action above
  Future<void> _runFirmwareUpgrade(
    BuildContext context,
    BeeSimAdapter adapter,
  ) async {
    final logs = ValueNotifier<List<String>>(<String>[]);
    final progress = ValueNotifier<_UpgradeProgress?>(null);
    final done = ValueNotifier<bool>(false);
    final awaitingConfirmation = ValueNotifier<bool>(false);
    Completer<bool>? confirmationDecision;
    var dialogClosed = false;

    void log(String line) {
      _log.info(line);
      logs.value = <String>[...logs.value, line];
    }

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BeeSimUpgradeDialog(
        logs: logs,
        progress: progress,
        done: done,
        awaitingConfirmation: awaitingConfirmation,
        onConfirmation: (confirmed) {
          final decision = confirmationDecision;
          if (decision != null && !decision.isCompleted) {
            decision.complete(confirmed);
          }
        },
      ),
    );
    unawaited(
      dialogFuture.whenComplete(() {
        dialogClosed = true;
        final decision = confirmationDecision;
        if (decision != null && !decision.isCompleted) {
          decision.complete(false);
        }
      }),
    );

    try {
      log('Checking current firmware state…');
      final status = await adapter.checkUpgrading();
      log(
        'Device reports crc=${status.crc} '
        'rows=${status.currentRow}/${status.totalRows}',
      );

      log('Querying BeeSIM for available firmware…');
      final upgrade = await _postUpgradeCheck(status);
      if (upgrade.status != 200) {
        log('Server rejected upgrade check: ${upgrade.message}');
        return;
      }
      if (upgrade.rows.isEmpty) {
        log('Firmware is already up to date.');
        return;
      }

      log(
        'Server returned ${upgrade.rows.length} rows '
        '(total=${upgrade.total}, resume index=${upgrade.index}).',
      );
      if (dialogClosed) {
        log('Firmware update cancelled before confirmation.');
        return;
      }

      final decision = Completer<bool>();
      confirmationDecision = decision;
      awaitingConfirmation.value = true;
      final confirmed = await decision.future;
      awaitingConfirmation.value = false;
      if (!confirmed) {
        log('Firmware update cancelled. No firmware rows were written.');
        return;
      }

      progress.value = _UpgradeProgress(
        current: upgrade.index,
        total: upgrade.total,
      );

      await adapter.runExclusive(() async {
        int n = upgrade.index;
        for (final row in upgrade.rows) {
          final ok = await adapter.writeFirmwareRow(
            totalRows: upgrade.total,
            currentRow: n,
            rowBytes: row,
          );
          if (!ok) {
            throw StateError(
              'Device rejected firmware row $n/${upgrade.total}.',
            );
          }
          progress.value = _UpgradeProgress(current: n, total: upgrade.total);
          n++;
        }

        log('All rows accepted. Resetting device…');
        await adapter.resetDevice();
      });
      log('Firmware update complete.');
    } catch (e, st) {
      log('Firmware update failed: $e');
      _log.severe('BeeSIM upgrade failed', e, st);
    } finally {
      done.value = true;
      await dialogFuture;
      awaitingConfirmation.dispose();
      done.dispose();
      progress.dispose();
      logs.dispose();
    }
  }

  Future<_UpgradeCheckResponse> _postUpgradeCheck(
    BeeSimUpgradeStatus status,
  ) async {
    const action = 'upgrade_check';
    final body = <String, dynamic>{
      'key': _upgradeKey,
      'crc': status.crc,
      'totalRows': status.totalRows,
      'currentRow': status.currentRow,
    };
    final params = <String, String>{'action': action};
    final bodyJson = jsonEncode(body);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final sign = _signRequest(params: params, body: bodyJson, ts: timestamp);

    final uri = Uri.parse(
      '$_apiBase/v2/plugin/mall/firmware.do',
    ).replace(queryParameters: params);

    final resp = await _httpClient
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json;charset=UTF-8',
            'X-Timestamp': timestamp,
            'X-Sign': sign,
          },
          body: bodyJson,
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      return _UpgradeCheckResponse(
        status: resp.statusCode,
        message: 'HTTP ${resp.statusCode}',
        rows: const <Uint8List>[],
        total: 0,
        index: 0,
      );
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final rawData = decoded['data'];
    final rows = <Uint8List>[];
    if (rawData is List) {
      for (final row in rawData) {
        if (row is String && row.isNotEmpty) {
          rows.add(HexUtils.hexToBytes(row));
        }
      }
    }
    return _UpgradeCheckResponse(
      status: (decoded['status'] as num?)?.toInt() ?? 200,
      message: decoded['msg']?.toString() ?? '',
      rows: rows,
      total: (decoded['total'] as num?)?.toInt() ?? rows.length,
      index: (decoded['index'] as num?)?.toInt() ?? 1,
    );
  }

  String _signRequest({
    required Map<String, String> params,
    required String body,
    required String ts,
  }) {
    // Replicates the JS client's `st()` signer:
    //   X-Sign = md5( base64utf8( params_qs + body + ts + SECRET ) )
    // params_qs is the unreserved `a=1&b=2` joining produced by `jt(params)`.
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final raw = '$qs$body$ts$_signSecret';
    final b64 = base64.encode(utf8.encode(raw));
    return md5.convert(utf8.encode(b64)).toString();
  }
}

class _UpgradeCheckResponse {
  const _UpgradeCheckResponse({
    required this.status,
    required this.message,
    required this.rows,
    required this.total,
    required this.index,
  });

  final int status;
  final String message;
  final List<Uint8List> rows;
  final int total;
  final int index;
}

class _UpgradeProgress {
  const _UpgradeProgress({required this.current, required this.total});
  final int current;
  final int total;
}

class _BeeSimUpgradeDialog extends StatelessWidget {
  const _BeeSimUpgradeDialog({
    required this.logs,
    required this.progress,
    required this.done,
    required this.awaitingConfirmation,
    required this.onConfirmation,
  });

  final ValueNotifier<List<String>> logs;
  final ValueNotifier<_UpgradeProgress?> progress;
  final ValueNotifier<bool> done;
  final ValueNotifier<bool> awaitingConfirmation;
  final ValueChanged<bool> onConfirmation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: done,
      builder: (context, isDone, _) => PopScope(
        canPop: isDone,
        child: AlertDialog(
          title: Text(l10n.beeSimFirmwareTitle),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: awaitingConfirmation,
                  builder: (_, needsConfirmation, _) {
                    if (!needsConfirmation) return const SizedBox.shrink();
                    final colors = Theme.of(context).colorScheme;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.beeSimFirmwareWarning,
                              style: TextStyle(color: colors.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<_UpgradeProgress?>(
                  valueListenable: progress,
                  builder: (_, p, _) {
                    if (p == null) return const SizedBox.shrink();
                    final fraction = p.total == 0 ? null : p.current / p.total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(value: fraction),
                          const SizedBox(height: 4),
                          Text('Row ${p.current} / ${p.total}'),
                        ],
                      ),
                    );
                  },
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: logs,
                    builder: (_, lines, _) => SingleChildScrollView(
                      reverse: true,
                      child: Text(
                        lines.join('\n'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: awaitingConfirmation,
              builder: (ctx, needsConfirmation, _) {
                if (needsConfirmation) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          onConfirmation(false);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => onConfirmation(true),
                        child: Text(l10n.beeSimFirmwareConfirm),
                      ),
                    ],
                  );
                }
                return TextButton(
                  onPressed: isDone ? () => Navigator.of(ctx).pop() : null,
                  child: Text(l10n.close),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
