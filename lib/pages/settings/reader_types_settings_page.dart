import 'package:flutter/material.dart';
import '../../settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/styled_header_scaffold.dart';
import '../../widgets/common/reader_api_icon.dart';
import '../../utils/platform_adapter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'remote_settings_page.dart';
import '../../l10n/app_localizations.dart';
import '../../config.dart';

class ReaderTypesSettingsPage extends StatelessWidget {
  const ReaderTypesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: AppSettings(),
      builder: (context, _) {
        return StyledHeaderScaffold(
          title: l10n.readerTypes,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int colCount = (width / 450).floor().clamp(1, 10);

              final List<Widget> sections = [
                _buildSection(
                  context,
                  title: l10n.enabledReaderTypes,
                  subtitle: l10n.enabledReaderTypesSubtitle,
                  children: [
                    if (!PlatformX.isWeb) _buildCcidConnectorSwitcher(context),
                    if (!PlatformX.isLinux) _buildBleConnectorSwitcher(context),
                    _buildRemoteConnectorSwitcher(context),
                    if (PlatformX.isAndroid) ...[
                      _buildQrtrConnectorSwitcher(context),
                      _buildSeHalConnectorSwitcher(context),
                      if (AppSettings().enableSeHalConnector)
                        ExpansionTile(
                          title: Text(l10n.seHalAdvancedSettings),
                          children: [
                            for (final slot in [1, 2])
                              SwitchListTile(
                                title: Text(l10n.seHalBorrowSlot(slot)),
                                subtitle: Text(l10n.seHalBorrowHint),
                                value: AppSettings().halUseBorrowed(slot),
                                onChanged: (value) async {
                                  if (value) {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(l10n.seHalBorrowTitle),
                                        content: Text(
                                          l10n.seHalBorrowWarning(slot),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              l10n.seHalBorrowConfirm,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                  }
                                  await AppSettings().setHalUseBorrowed(
                                    slot,
                                    value,
                                  );
                                },
                              ),
                          ],
                        ),
                      _buildOmapiConnectorSwitcher(context),
                      if (kIsPrivileged) _buildTmapiConnectorSwitcher(context),
                    ],
                  ],
                ),
                if (AppSettings().enableRemoteConnector)
                  _buildSection(
                    context,
                    title: l10n.remoteReaderSettings,
                    subtitle: l10n.remoteReaderSettingsSubtitle,
                    children: [_buildRemoteSettingsLink(context)],
                  ),
              ];

              return MasonryGridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: colCount,
                mainAxisSpacing: 32,
                crossAxisSpacing: 32,
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  return sections[index];
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 2.0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) _buildDivider(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      indent: 72,
      color: theme.dividerColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
      ),
    );
  }

  Widget _buildResponsiveTile(
    BuildContext context, {
    required Widget icon,
    required String title,
    String? subtitle,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 20,
    ),
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceSubtle(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSwitch(
    BuildContext context,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Switch(value: value, onChanged: enabled ? onChanged : null);
  }

  Widget _buildCcidConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.usb_rounded, size: 20, color: Colors.orange),
      ),
      title: l10n.ccidReaderTitle,
      subtitle: l10n.ccidReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableCcidConnector,
        (v) => settings.setEnableCcidConnector(v),
      ),
      onTap: () =>
          settings.setEnableCcidConnector(!settings.enableCcidConnector),
    );
  }

  Widget _buildQrtrConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.memory_rounded, size: 20, color: Colors.teal),
      ),
      title: l10n.qrtrReaderTitle,
      subtitle: l10n.qrtrReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableQrtrConnector,
        (v) => settings.setEnableQrtrConnector(v),
      ),
      onTap: () =>
          settings.setEnableQrtrConnector(!settings.enableQrtrConnector),
    );
  }

  Widget _buildSeHalConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.memory_rounded, size: 20, color: Colors.teal),
      ),
      title: l10n.seHalReaderTitle,
      subtitle: l10n.seHalReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableSeHalConnector,
        (v) => settings.setEnableSeHalConnector(v),
      ),
      onTap: () =>
          settings.setEnableSeHalConnector(!settings.enableSeHalConnector),
    );
  }

  Widget _buildBleConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.bluetooth_rounded,
          size: 20,
          color: Colors.blue,
        ),
      ),
      title: l10n.bluetoothReaderTitle,
      subtitle: l10n.bluetoothReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableBleConnector,
        (v) => settings.setEnableBleConnector(v),
      ),
      onTap: () => settings.setEnableBleConnector(!settings.enableBleConnector),
    );
  }

  Widget _buildRemoteConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.cloud_outlined, size: 20, color: Colors.purple),
      ),
      title: l10n.remoteReadersTitle,
      subtitle: l10n.remoteReadersConnectorSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableRemoteConnector,
        (v) => settings.setEnableRemoteConnector(v),
      ),
      onTap: () =>
          settings.setEnableRemoteConnector(!settings.enableRemoteConnector),
    );
  }

  Widget _buildOmapiConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const ReaderApiIcon(
          type: ReaderApiIconType.omapi,
          size: 20,
          color: Colors.green,
        ),
      ),
      title: l10n.omapiReaderTitle,
      subtitle: l10n.omapiReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableOmapiConnector,
        (v) => settings.setEnableOmapiConnector(v),
      ),
      onTap: () =>
          settings.setEnableOmapiConnector(!settings.enableOmapiConnector),
    );
  }

  Widget _buildTmapiConnectorSwitcher(BuildContext context) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const ReaderApiIcon(
          type: ReaderApiIconType.telephony,
          size: 20,
          color: Colors.teal,
        ),
      ),
      title: l10n.tmapiReaderTitle,
      subtitle: l10n.tmapiReaderSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.enableTmapiConnector,
        (v) => settings.setEnableTmapiConnector(v),
      ),
      onTap: () =>
          settings.setEnableTmapiConnector(!settings.enableTmapiConnector),
    );
  }

  Widget _buildRemoteSettingsLink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.settings_remote_rounded,
          size: 20,
          color: Colors.purple,
        ),
      ),
      title: l10n.remoteServerConfiguration,
      subtitle: l10n.remoteServerConfigurationSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RemoteSettingsPage()),
      ),
    );
  }
}
