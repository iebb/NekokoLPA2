import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/euicc_profile.dart';
import '../pages/vowifi_sms_page.dart';
import '../services/vowifi_sms_service.dart';
import '../widgets/profiles_screen/action_button.dart';
import '../settings/app_settings.dart';
import '../utils/vowifi_reader_support.dart';
import 'plugin_base.dart';

class VowifiPlugin extends ProfilePlugin {
  @override
  String get id => 'vowifi';

  @override
  String get name => 'VoWiFi';

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  List<PluginSettingsToggle> settingsToggles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = AppSettings();
    final toggles = <PluginSettingsToggle>[
      PluginSettingsToggle(
        icon: Icons.wifi_calling_3_outlined,
        color: Colors.blueAccent,
        title: l10n.vowifi,
        subtitle: l10n.vowifiSubtitle,
        value: settings.vowifiEnabled,
        onChanged: _setEnabled,
      ),
    ];
    if (settings.vowifiEnabled) {
      toggles.add(
        PluginSettingsToggle(
          icon: Icons.autorenew,
          color: Colors.teal,
          title: l10n.vowifiAutoRenewTitle,
          subtitle: l10n.vowifiAutoRenewSubtitle,
          value: settings.vowifiAutoRenew,
          onChanged: (context, value) => settings.setVowifiAutoRenew(value),
        ),
      );
    }
    return toggles;
  }

  Future<void> _setEnabled(BuildContext context, bool enabled) async {
    final settings = AppSettings();
    if (!enabled) {
      await settings.setVowifiEnabled(false);
      await VowifiSmsService().disableAndDisconnect();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vowifiDisclaimerTitle),
        content: Text(l10n.vowifiDisclaimerBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.enable),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings.setVowifiEnabled(true, disclaimerAccepted: true);
    }
  }

  @override
  List<Widget> buildReaderActions(
    BuildContext context,
    ReaderActionContext actionContext,
  ) {
    final settings = AppSettings();
    if (!settings.vowifiEnabled) return [];
    final reader = actionContext.reader;
    final supportedReader = supportsVowifiReader(
      reader,
      adapter: actionContext.adapter,
    );
    return <Widget>[
      ActionButton(
        icon: Icons.wifi_calling_3,
        onPressed: !supportedReader
            ? null
            : () => _loadCurrentSimToVowifi(context, actionContext),
        label: 'Load current SIM to VoWiFi',
      ),
    ];
  }

  @override
  AppTabSpec get appTab => const AppTabSpec(
    id: 'vowifi',
    label: 'VoWiFi',
    icon: Icons.wifi_calling_3_outlined,
    activeIcon: Icons.wifi_calling_3,
    builder: _buildPage,
  );

  static Widget _buildPage(BuildContext context) {
    return const VowifiSmsPage();
  }

  Future<void> _loadCurrentSimToVowifi(
    BuildContext context,
    ReaderActionContext actionContext,
  ) async {
    final reader = actionContext.reader;
    if (reader == null) {
      return;
    }
    final activeProfile = actionContext.profiles
        ?.where((profile) => profile.enabled)
        .firstOrNull;
    final logs = ValueNotifier<List<String>>(<String>[]);
    final done = ValueNotifier<bool>(false);
    final title = ValueNotifier<String>('Loading current SIM to VoWiFi');
    final scrollController = ScrollController();

    void appendLog(String line) {
      logs.value = <String>[...logs.value, line];
    }

    void scrollToBottom() {
      if (!scrollController.hasClients) {
        return;
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }

    logs.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    });

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final isQitta = AppSettings().variant == 'qitta';
          return AlertDialog(
            title: ValueListenableBuilder<String>(
              valueListenable: title,
              builder: (context, value, _) => Text(value),
            ),
            content: SizedBox(
              width: isQitta ? 640 : 400,
              child: ValueListenableBuilder<bool>(
                valueListenable: done,
                builder: (context, isDone, _) {
                  return ValueListenableBuilder<List<String>>(
                    valueListenable: logs,
                    builder: (context, value, _) {
                      if (isQitta) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: SelectableText(
                            value.isEmpty ? 'Starting...' : value.join('\n'),
                            style: GoogleFonts.ibmPlexMono(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      }
                      final lastLine = value.isEmpty
                          ? 'Starting...'
                          : value.last;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isDone) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            lastLine,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: done,
                builder: (context, value, _) {
                  return TextButton(
                    onPressed: value
                        ? () => Navigator.of(dialogContext).pop()
                        : null,
                    child: const Text('Close'),
                  );
                },
              ),
            ],
          );
        },
      ).whenComplete(scrollController.dispose),
    );

    try {
      appendLog('Selected reader: ${reader.name}');
      await VowifiSmsService().connectCurrentCard(
        adapter: actionContext.adapter,
        reader: reader,
        activeProfile: activeProfile,
        onLog: appendLog,
      );
      title.value = 'VoWiFi load complete';
      appendLog('Session created successfully.');
      done.value = true;
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded current SIM from ${reader.name} into VoWiFi.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      title.value = 'VoWiFi load failed';
      appendLog('ERROR: $error');
      done.value = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('VoWiFi load failed: $error')));
    }
  }
}
