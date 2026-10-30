import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../settings/app_settings.dart';
import '../../adapter/ble/ble_manager.dart';
import '../../utils/platform_adapter.dart';
import '../common/loading_spinner.dart';
import 'ble_scan_dialog.dart';
import '../../adapter/composite_adapter.dart';

/// Base widget for displaying state messages in the profiles screen.
class ColumnStateMessage extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color? iconContainerColor;

  const ColumnStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions,
    this.iconContainerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    iconContainerColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceSubtle(context),
                  height: 1.4,
                ),
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BluetoothConnectionErrorState extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  const BluetoothConnectionErrorState({
    super.key,
    this.error,
    required this.onRetry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(
        error == null
            ? Icons.bluetooth_rounded
            : Icons.bluetooth_disabled_rounded,
        size: 64,
        color: error == null
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
      ),
      iconContainerColor:
          (error == null ? theme.colorScheme.primary : theme.colorScheme.error)
              .withValues(alpha: 0.1),
      title: error == null
          ? l10n.bluetoothNotConnected
          : l10n.bluetoothConnectionFailed,
      subtitle: error == null
          ? l10n.bluetoothNotConnectedSubtitle
          : l10n.bluetoothConnectionFailedSubtitle(error!),
      actions: [
        OutlinedButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.removeDevice),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retryConnection),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class RemoteConnectionErrorState extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onChangeSettings;

  const RemoteConnectionErrorState({
    super.key,
    this.error,
    required this.onRetry,
    required this.onChangeSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(
        Icons.cloud_off_rounded,
        size: 64,
        color: theme.colorScheme.error,
      ),
      iconContainerColor: theme.colorScheme.error.withValues(alpha: 0.1),
      title: l10n.remoteReaderConnectionFailed,
      subtitle: l10n.remoteReaderConnectionFailedSubtitle(
        error ?? 'Unknown error',
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: onChangeSettings,
          icon: const Icon(Icons.settings_remote_outlined),
          label: Text(l10n.changeSettings),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retryConnection),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class NoReadersState extends StatelessWidget {
  final bool isLoading;
  final String? operationLoadingMessage;

  final VoidCallback onConnectRemote;
  final Function(String) onReaderSelected;
  final Future<void> Function() onReadersLoaded; // Changed to Future
  final VoidCallback onScanStarted;

  const NoReadersState({
    super.key,
    required this.isLoading,
    this.operationLoadingMessage,
    required this.onConnectRemote,
    required this.onReaderSelected,
    required this.onReadersLoaded,
    required this.onScanStarted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingSpinner(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              operationLoadingMessage ?? l10n.initializing,
              style: TextStyle(color: AppTheme.onSurfaceSubtle(context)),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cast_connected_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.connectCompatibleReader,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        PlatformX.supportsBle &&
                                AppSettings().enableBleConnector
                            ? l10n.connectReaderSubtitleBle
                            : l10n.connectReaderSubtitleCcid,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.onSurfaceSubtle(context),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (PlatformX.supportsBle &&
                          AppSettings().enableBleConnector)
                        _ConnectOptionCard(
                          icon: Icons.bluetooth_searching_rounded,
                          title: l10n.scanForBluetooth,
                          subtitle: kIsWeb
                              ? 'Web Bluetooth API'
                              : 'Bluetooth LE',
                          colors: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                          onTap: () async {
                            String? newReaderId;
                            if (kIsWeb) {
                              try {
                                newReaderId = await BleManager()
                                    .scanAndAddReaderForWeb();
                                if (newReaderId != null) {
                                  await onReadersLoaded(); // Use await
                                  onReaderSelected(newReaderId);
                                }
                              } catch (e) {
                                // user cancelled or error
                              } finally {
                                await onReadersLoaded();
                              }
                            } else {
                              newReaderId = await showBluetoothReaderPicker(
                                context,
                              );
                              if (newReaderId != null) {
                                await onReadersLoaded();
                                onReaderSelected(newReaderId);
                              }
                            }
                          },
                        ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 16),
                        _ConnectOptionCard(
                          icon: Icons.usb_rounded,
                          title: 'Connect USB Reader',
                          subtitle: 'WebUSB (SCRP Protocol)',
                          colors: const [Color(0xFF009688), Color(0xFF00796B)],
                          onTap: () async {
                            try {
                              final reader = await CompositeAdapter()
                                  .scanScrp();
                              if (reader != null) {
                                await onReadersLoaded();
                                onReaderSelected(reader.id);
                              }
                            } catch (e) {
                              // ignore
                            } finally {
                              // refresh will handle clearing loading if it succeeds,
                              // but we should ensure it's cleared if cancelled.
                              await onReadersLoaded();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _ConnectOptionCard(
                          icon: Icons.extension_rounded,
                          title: l10n.downloadExtension,
                          subtitle: 'WebCard Browser Extension',
                          colors: const [Color(0xFFFF9800), Color(0xFFF57C00)],
                          onTap: () async {
                            final uri = Uri.parse(
                              "https://webcard.cardid.org/",
                            );
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                      if (AppSettings().remoCardUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ConnectOptionCard(
                          icon: Icons.cloud_sync_rounded,
                          title: l10n.connectRemote,
                          subtitle: 'Remote Cloud Reader',
                          colors: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                          onTap: onConnectRemote,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ConnectOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_ConnectOptionCard> createState() => _ConnectOptionCardState();
}

class _ConnectOptionCardState extends State<_ConnectOptionCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: widget.colors[0].withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _isHovering
                  ? widget.colors[0].withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: _isHovering ? 2.0 : 1.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.onSurfaceSubtle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _isHovering
                        ? widget.colors[0]
                        : AppTheme.onSurfaceVerySubtle(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnsupportedCardState extends StatelessWidget {
  final bool isTelephony;
  final bool isOmapi;
  final VoidCallback onRetry;
  final VoidCallback onAboutAram;
  final String? operatorIconBase64;
  final String? fallbackDetails;

  const UnsupportedCardState({
    super.key,
    required this.isTelephony,
    required this.isOmapi,
    required this.onRetry,
    required this.onAboutAram,
    this.operatorIconBase64,
    this.fallbackDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subtitle = <String>[
      l10n.cardUnsupportedSubtitle,
      if (fallbackDetails != null && fallbackDetails!.trim().isNotEmpty)
        fallbackDetails!.trim(),
    ].join('\n\n');

    return ColumnStateMessage(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sd_card_alert_rounded,
            size: 52,
            color: theme.colorScheme.error,
          ),
          if (operatorIconBase64 != null && operatorIconBase64!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Image.memory(
                base64Decode(operatorIconBase64!),
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => Icon(
                  Icons.perm_media_outlined,
                  color: AppTheme.onSurfaceSubtle(context),
                ),
              ),
            ),
          ],
        ],
      ),
      iconContainerColor: theme.colorScheme.error.withValues(alpha: 0.1),
      title: l10n.cardUnsupported,
      subtitle: subtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse("https://nekoko.lpa.ee/products");
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.devices_other_outlined, size: 18),
          label: Text(l10n.supportedDevices),
        ),
        if (!isTelephony)
          OutlinedButton.icon(
            onPressed: onAboutAram,
            icon: const Icon(Icons.info_outline, size: 18),
            label: Text(l10n.aboutAram),
          ),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.retry),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class AramFailedState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onAboutAram;

  const AramFailedState({
    super.key,
    required this.onRetry,
    required this.onAboutAram,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(Icons.lock_person_outlined, size: 64, color: Colors.orange),
      iconContainerColor: Colors.orange.withValues(alpha: 0.1),
      title: l10n.accessDenied,
      subtitle: l10n.accessDeniedSubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse("https://nekoko.lpa.ee/products");
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.devices_other_outlined, size: 18),
          label: Text(l10n.supportedDevices),
        ),
        OutlinedButton.icon(
          onPressed: onAboutAram,
          icon: const Icon(Icons.info_outline, size: 18),
          label: Text(l10n.aboutAram),
        ),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.retry),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class NoCardDetectedState extends StatelessWidget {
  final VoidCallback onRefresh;

  const NoCardDetectedState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(
        Icons.credit_card_off_rounded,
        size: 64,
        color: AppTheme.onSurfaceSubtle(context),
      ),
      iconContainerColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      title: l10n.noCardDetected,
      subtitle:
          "${l10n.noCardDetectedSubtitle}\n\nOn some platforms it might be required to re-plug the reader to use a different card",
      actions: [
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.refresh),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class ConnectingToReaderState extends StatelessWidget {
  final String? message;

  const ConnectingToReaderState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: LoadingSpinner(size: 48, color: theme.colorScheme.primary),
      title: message ?? l10n.connectingToReader,
    );
  }
}

class NotLoadedState extends StatelessWidget {
  final VoidCallback onLoad;

  const NotLoadedState({super.key, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(
        Icons.link_off,
        size: 80,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      title: l10n.noDataLoaded,
      actions: [
        ElevatedButton.icon(
          onPressed: onLoad,
          icon: const Icon(Icons.link, size: 18),
          label: Text(l10n.loadProfiles),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class NoProfilesState extends StatelessWidget {
  final VoidCallback onRefresh;

  const NoProfilesState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ColumnStateMessage(
      icon: Icon(
        Icons.sim_card_alert_outlined,
        size: 80,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      title: l10n.noProfilesInstalled,
      subtitle: l10n.noProfilesInstalledSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.refresh),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
