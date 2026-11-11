import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../adapter/euicc_adapter.dart';
import '../l10n/app_localizations.dart';
import '../logic/profile_manager.dart';
import '../models/euicc_profile.dart';
import '../services/notification_service.dart';
import '../services/smds_discovery_service.dart';
import '../services/transfer_downloader.dart';
import '../settings/app_settings.dart';
import '../ts43/entitlement.dart';
import '../ts43/enums.dart';
import '../ts43/errors.dart';
import '../ts43/sim/identity.dart';
import '../ts43/source_sim_channel.dart';
import '../ts43/ts43_client.dart';
import '../ts43/types.dart';
import '../ts43/websheet.dart';
import '../utils/imei_codec.dart';

/// Multi-step wizard driving a TS.43 carrier-managed eSIM transfer of an
/// eligible (enabled) source profile onto the managed eUICC.
class EsimTransferPage extends StatefulWidget {
  final ProfileManager manager;
  final Adapter adapter;
  final Reader reader;
  final EuiccProfile profile;

  const EsimTransferPage({
    super.key,
    required this.manager,
    required this.adapter,
    required this.reader,
    required this.profile,
  });

  @override
  State<EsimTransferPage> createState() => _EsimTransferPageState();
}

enum _Phase { working, terminalSuccess, terminalInfo, error }

class _EsimTransferPageState extends State<EsimTransferPage> {
  static final Logger _log = Logger('EsimTransferPage');

  _Phase _phase = _Phase.working;
  String _status = '';
  String? _message;
  String? _error;
  double? _progress;

  SourceSimChannel? _source;
  Ts43Client? _client;
  Identity? _identity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _client?.dispose();
    _source?.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _setStatus(String s, {double? progress}) {
    if (!mounted) return;
    setState(() {
      _status = s;
      _progress = progress;
    });
  }

  Future<void> _run() async {
    try {
      await widget.adapter.connect(widget.reader);

      // 1. Ensure the source profile is enabled and read the target EID.
      _setStatus(_l10n.transferEnablingSource);
      String? targetEid;
      final session = await widget.manager.openSession();
      try {
        if (!widget.profile.enabled) {
          await widget.manager.enableProfile(
            widget.profile.rawIccid,
            useChannel: session,
          );
        }
        try {
          targetEid = await widget.manager.getEid(useChannel: session);
        } catch (e) {
          _log.warning('Failed to read target EID: $e');
        }
      } finally {
        await session.close();
      }

      // 2. Read the source SIM identity over its USIM applet.
      _setStatus(_l10n.transferReadingSource);
      _source = SourceSimChannel(widget.adapter);
      try {
        _identity = await _source!.probe();
      } on SourceSimUnavailable catch (e) {
        _log.warning('Source SIM unavailable: $e');
        _terminalError(_l10n.transferIneligibleReader);
        return;
      }

      // 3. Discover the carrier entitlement configuration.
      _setStatus(_l10n.transferCheckingEligibility);
      Entitlement entitlement;
      try {
        entitlement = await Ts43EntitlementDb.discover(
          _identity!,
          SimType.esim,
        );
      } on EntitlementException catch (e) {
        _log.warning('Entitlement discovery failed: $e');
        _terminalError(_l10n.transferNoEntitlement);
        return;
      }

      // 4. Build the target device + TS.43 client.
      final imeiBytes = await AppSettings().getImei();
      final imei = imeiDigitsFromStoredBytes(imeiBytes);
      final target = Device(imei: imei, eid: targetEid ?? '');
      final source = Device(
        imei: imei,
        iccid: _identity!.iccid,
        eid: targetEid ?? '',
      );

      _client = Ts43Client(
        Ts43Config(
          entitlement: entitlement,
          source: Endpoint(channel: _source, device: source),
          target: Endpoint(device: target),
          appVersion: '1',
        ),
      );

      // 5. Run the transfer state machine.
      _setStatus(_l10n.transferContactingCarrier);
      var result = await _client!.transfer();
      await _drive(result);
    } catch (e, st) {
      _log.severe('Transfer failed: $e', e, st);
      _terminalError(_l10n.transferFailed(e.toString()));
    }
  }

  Future<void> _drive(Ts43Result result) async {
    while (mounted) {
      switch (result.state) {
        case Ts43State.done:
          _terminalSuccess();
          return;
        case Ts43State.dismissed:
          _terminalInfo(_l10n.transferDismissed);
          return;
        case Ts43State.pendingActivation:
          _terminalInfo(_l10n.transferPendingActivation);
          return;
        case Ts43State.pendingUserInput:
          final event = result.event as UserInputEvent;
          final answer = await _askUserInput(event.message);
          if (answer == null) return;
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.continueFlow(
            result,
            ContinueRequest(userInput: answer),
          );
          break;
        case Ts43State.pendingWebsheet:
          final event = result.event as WebsheetEvent;
          final ws = await _openWebsheet(event.websheet);
          if (ws == null) return;
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.continueFlow(
            result,
            ContinueRequest(websheet: ws),
          );
          break;
        case Ts43State.pendingSourceProfileDeletion:
          final event = result.event as SourceProfileDeletionEvent;
          final ok = await _deleteSourceProfile(event.iccid);
          if (!ok) return;
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.continueFlow(
            result,
            const ContinueRequest(sourceProfileDeleted: true),
          );
          break;
        case Ts43State.pendingDownload:
          final iccid = await _downloadProfile(result.downloadConfig);
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.completeActivation(
            result,
            ActivationResult(iccid: iccid ?? ''),
          );
          break;
        case Ts43State.pendingSmdsDiscovery:
          final iccid = await _smdsDiscoverAndDownload();
          if (iccid == null) return; // terminal state handled or cancelled
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.completeActivation(
            result,
            ActivationResult(iccid: iccid),
          );
          break;
        case Ts43State.pendingDelayedDownload:
          final iccid = await _promptInstalledIccid();
          if (iccid == null) return;
          _setStatus(_l10n.transferContactingCarrier);
          result = await _client!.completeActivation(
            result,
            ActivationResult(iccid: iccid),
          );
          break;
        default:
          _terminalInfo(_l10n.transferPendingActivation);
          return;
      }
    }
  }

  // ---- Event handlers ----

  Future<UserInputResult?> _askUserInput(Message message) async {
    final controller = TextEditingController();
    return showDialog<UserInputResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            message.title.isNotEmpty ? message.title : _l10n.transferTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.text.isNotEmpty) Text(message.text),
              if (message.acceptFreeText) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: message.acceptFreeTextHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (message.rejectButton)
              TextButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  const UserInputResult(button: MessageButton.rejected),
                ),
                child: Text(
                  message.rejectButtonLabel.isNotEmpty
                      ? message.rejectButtonLabel
                      : _l10n.transferReject,
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                UserInputResult(
                  response: controller.text,
                  button: MessageButton.accepted,
                ),
              ),
              child: Text(
                message.acceptButtonLabel.isNotEmpty
                    ? message.acceptButtonLabel
                    : _l10n.transferAccept,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<WebsheetResult?> _openWebsheet(Websheet websheet) async {
    return Navigator.push<WebsheetResult>(
      context,
      MaterialPageRoute(builder: (_) => _WebsheetPage(websheet: websheet)),
    );
  }

  Future<bool> _deleteSourceProfile(String iccid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.transferDeleteSourceTitle),
        content: Text(_l10n.transferDeleteSourceBody(iccid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n.transferClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l10n.transferDeleteSourceConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    // Free the source USIM channel before driving ISD-R operations.
    await _source?.dispose();
    _setStatus(_l10n.transferEnablingSource);
    final session = await widget.manager.openSession();
    try {
      await widget.manager.disableProfile(iccid, useChannel: session);
      await widget.manager.deleteProfile(iccid, useChannel: session);
      final settings = AppSettings();
      if (settings.isAnyNotificationProcessingEnabled) {
        try {
          await NotificationService().processPendingNotifications(
            widget.manager,
            session,
            autoSendInstall: settings.notifAutoSendInstall,
            autoRemoveInstall: settings.notifAutoRemoveInstall,
            autoSendEnable: settings.notifAutoSendEnable,
            autoRemoveEnable: settings.notifAutoRemoveEnable,
            deleteWithoutSendingEnable:
                settings.notifDeleteWithoutSendingEnable,
            autoSendDisable: settings.notifAutoSendDisable,
            autoRemoveDisable: settings.notifAutoRemoveDisable,
            deleteWithoutSendingDisable:
                settings.notifDeleteWithoutSendingDisable,
            autoSendDelete: settings.notifAutoSendDelete,
            autoRemoveDelete: settings.notifAutoRemoveDelete,
          );
        } catch (e) {
          _log.warning('Source delete notification failed: $e');
        }
      }
    } finally {
      await session.close();
    }
    return true;
  }

  Future<String?> _downloadProfile(DownloadConfig config) async {
    _setStatus(_l10n.transferDownloadingProfile, progress: 0);
    final code = config.activationCode.isNotEmpty
        ? config.activationCode
        : 'LPA:1\$${config.smdpFqdn}\$${config.matchingId}';
    // The downloader opens its own ISD-R session; the source USIM channel stays
    // open (idle) so a later AcquireConfiguration EAP relay can reuse it.
    final downloader = TransferDownloader(
      manager: widget.manager,
      adapter: widget.adapter,
      reader: widget.reader,
    );
    final result = await downloader.downloadInstallEnable(
      activationCode: code,
      onStatus: (m) => _setStatus(m, progress: _progress),
      onProgress: (p) =>
          _setStatus(_l10n.transferDownloadingProfile, progress: p),
    );
    return (result.iccid?.isNotEmpty ?? false)
        ? result.iccid
        : config.profileIccid;
  }

  Future<String?> _promptInstalledIccid() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.transferTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_l10n.transferDelayedDownload),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _l10n.transferInstalledIccid,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.transferClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(_l10n.transferContinue),
          ),
        ],
      ),
    );
  }

  /// Runs SM-DS (ES11) discovery, lets the user pick a pending profile, then
  /// downloads it. Returns the installed ICCID, or null if there was nothing to
  /// download or the user cancelled (terminal state is set as needed).
  Future<String?> _smdsDiscoverAndDownload() async {
    _setStatus(_l10n.transferSmdsDiscovering);
    final imei = await AppSettings().getImei();
    final service = SmdsDiscoveryService(
      manager: widget.manager,
      adapter: widget.adapter,
      reader: widget.reader,
    );
    final events = await service.discover(
      smdsAddress: kRootSmdsAddress,
      imei: imei,
    );
    if (events.isEmpty) {
      _terminalInfo(_l10n.transferSmdsNoProfiles);
      return null;
    }
    final chosen = events.length == 1
        ? events.first
        : await _selectEvent(events);
    if (chosen == null) return null;
    return _downloadProfile(
      DownloadConfig(smdpFqdn: chosen.address, matchingId: chosen.eventId),
    );
  }

  Future<DiscoveredEvent?> _selectEvent(List<DiscoveredEvent> events) {
    return showDialog<DiscoveredEvent>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(_l10n.transferSelectProfile),
        children: [
          for (final e in events)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e),
              child: Text(_l10n.transferProfileOnServer(e.eventId, e.address)),
            ),
        ],
      ),
    );
  }

  // ---- Terminal states ----

  void _terminalSuccess() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.terminalSuccess;
      _message = _l10n.transferSuccess;
    });
  }

  void _terminalInfo(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.terminalInfo;
      _message = message;
    });
  }

  void _terminalError(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_l10n.transferTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.working:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_progress != null)
              LinearProgressIndicator(value: _progress)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(_status, textAlign: TextAlign.center),
            if (_identity != null) ...[
              const SizedBox(height: 12),
              Text(
                _l10n.transferSourceCarrier(_identity!.mccMnc),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      case _Phase.terminalSuccess:
        return _Result(
          icon: Icons.check_circle,
          color: Colors.green,
          message: _message ?? '',
          onClose: () => Navigator.pop(context, true),
          closeLabel: _l10n.transferClose,
        );
      case _Phase.terminalInfo:
        return _Result(
          icon: Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
          message: _message ?? '',
          onClose: () => Navigator.pop(context, false),
          closeLabel: _l10n.transferClose,
        );
      case _Phase.error:
        return _Result(
          icon: Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          message: _error ?? '',
          onClose: () => Navigator.pop(context, false),
          closeLabel: _l10n.transferClose,
        );
    }
  }
}

class _Result extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback onClose;
  final String closeLabel;
  const _Result({
    required this.icon,
    required this.color,
    required this.message,
    required this.onClose,
    required this.closeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton(onPressed: onClose, child: Text(closeLabel)),
      ],
    );
  }
}

/// In-app WebView that hosts the carrier websheet and captures the ODSA
/// callback via an injected JS bridge or a `/_callback` navigation.
class _WebsheetPage extends StatefulWidget {
  final Websheet websheet;
  const _WebsheetPage({required this.websheet});

  @override
  State<_WebsheetPage> createState() => _WebsheetPageState();
}

class _WebsheetPageState extends State<_WebsheetPage> {
  static final Logger _log = Logger('Websheet');
  late final WebViewController _controller;
  bool _completed = false;

  static const _bridge = '''
(function(g){
  function post(line){ try { TS43Channel.postMessage(line); } catch(e){} }
  g.addEventListener('ts43-odsa-callback', function(ev){
    try { post('TS43_ODSA_CALLBACK ' + JSON.stringify(ev.detail)); } catch(e){}
  });
  var orig = g.console && g.console.log;
  if (orig) {
    g.console.log = function(){
      try {
        var s = Array.prototype.join.call(arguments, ' ');
        if (s.indexOf('TS43_ODSA_CALLBACK') === 0 || s.indexOf('TS43_VOWIFI_CALLBACK') === 0) post(s);
      } catch(e){}
      return orig.apply(g.console, arguments);
    };
  }
})(window);
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TS43Channel',
        onMessageReceived: (msg) => _onCallback(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // Inject the bundled ODSA bridge then our channel forwarder.
            try {
              await _controller.runJavaScript(_bridge);
            } catch (e) {
              _log.warning('Bridge injection failed: $e');
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('/_callback')) {
              _onCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    final uri = Uri.tryParse(widget.websheet.url);
    if (uri != null) {
      _controller.loadRequest(uri);
    }
  }

  void _onCallback(String raw) {
    if (_completed) return;
    try {
      final result = parseWebsheetResult(raw);
      _completed = true;
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      _log.fine('Ignoring non-callback message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.transferTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
