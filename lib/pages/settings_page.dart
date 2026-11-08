import 'package:flutter/material.dart';
import '../settings/app_settings.dart';
import '../plugins/plugin_base.dart';
import '../plugins/plugin_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/styled_header_scaffold.dart';
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import '../services/database_service.dart';
import '../services/rsp_proxy_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'notification_history_page.dart';
import 'settings/aid_settings_page.dart';
import 'settings/notifications_settings_page.dart';
import 'settings/stats_settings_page.dart';
import 'settings/display_settings_page.dart';
import 'settings/redaction_settings_page.dart';
import 'settings/reader_types_settings_page.dart';
import 'settings/ble_devices_settings_page.dart';
import 'app_logs_page.dart';
import 'adb_bridge_connect_page.dart';
import 'settings/tags_and_reminders_page.dart';

import '../l10n/app_localizations.dart';
import '../utils/platform_adapter.dart';
import '../utils/imei_codec.dart';
import '../services/update_service.dart';
import '../utils/update_utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildAdaptiveDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    final theme = Theme.of(context);
    final currentItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.firstWhere(
        (item) => item.value == 'null',
        orElse: () => items.first,
      ),
    );
    final safeValue = currentItem.value;

    return Theme(
      data: theme.copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: safeValue,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor),
        ),
        color: theme.colorScheme.surface,
        elevation: 8,
        onSelected: onChanged,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  child: currentItem.child,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ],
          ),
        ),
        itemBuilder: (context) {
          return items.map((item) {
            final isSelected = item.value == safeValue;
            return PopupMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : AppTheme.onSurfaceSubtle(context),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                      child: item.child,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
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
    required double screenWidth,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 20,
    ),
  }) {
    final theme = Theme.of(context);
    final showIcon = screenWidth >= 400;
    final isVertical = screenWidth < 300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: isVertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showIcon) ...[icon, const SizedBox(width: 16)],
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: child),
                  ],
                )
              : Row(
                  children: [
                    if (showIcon) ...[icon, const SizedBox(width: 16)],
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings(),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return StyledHeaderScaffold(
          title: l10n.settingsTitle,
          subtitle: AppSettings().versionDisplay,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // "for every 450px add 1 more column"
              final int colCount = (width / 450).floor().clamp(1, 10);

              // Define all sections in order
              final List<Widget> allSections = [
                _buildSection(
                  context,
                  title: l10n.appearance,
                  children: [
                    _buildLanguageSelector(context, width),
                    _buildThemeSwitcher(context, width),
                    _buildResponsiveTile(
                      context,
                      screenWidth: width,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          size: 20,
                          color: Colors.purple,
                        ),
                      ),
                      title: l10n.displaySettings,
                      subtitle: l10n.appearanceSubtitle,
                      child: Icon(
                        Icons.chevron_right,
                        color: AppTheme.onSurfaceVerySubtle(context),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DisplaySettingsPage(),
                        ),
                      ),
                    ),
                    _buildResponsiveTile(
                      context,
                      screenWidth: width,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                      title: 'Redaction',
                      subtitle: 'Control on-screen privacy for profile data',
                      child: Icon(
                        Icons.chevron_right,
                        color: AppTheme.onSurfaceVerySubtle(context),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RedactionSettingsPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildNotificationsSection(context, width),
                _buildTagsAndRemindersLink(context, width),
                _buildSection(
                  context,
                  title: l10n.connectivity,
                  children: [
                    _buildReaderTypesLink(context, width),
                    _buildBleDevicesLink(context, width),
                    if (PlatformX.isAndroid && AppSettings().rootDetected)
                      _buildOtBridgeHintTile(context, width),
                    if (PlatformX.isAndroid)
                      _buildAdbBridgeTile(context, width),
                    for (final toggle in PluginManager().settingsToggles(
                      context,
                    ))
                      _buildPluginToggle(context, width, toggle),
                  ],
                ),
                _buildSection(
                  context,
                  title: l10n.transport,
                  children: [
                    _buildLoadProfileIconsSwitcher(context, width),
                    _buildRspProxyTile(context, width),
                    _buildManageAidsLink(context, width),
                    if (AppSettings().developerModeEnabled) ...[
                      _buildDisableRefreshFlagsSwitcher(context, width),
                      _buildMssSlider(context, width),
                    ],
                  ],
                ),
                _buildSection(
                  context,
                  title: l10n.analytics,
                  children: [_buildStatsLink(context, width)],
                ),
                _buildSection(
                  context,
                  title: l10n.downloadProfile,
                  children: [_buildImeiSelector(context, width)],
                ),
                _buildSection(
                  context,
                  title: l10n.database,
                  children: [
                    _buildExportDatabase(context, width),
                    _buildImportDatabase(context, width),
                    if (AppSettings().developerModeEnabled)
                      _buildResetDatabase(context, width),
                    if (PlatformX.isWindows ||
                        PlatformX.isMacOS ||
                        PlatformX.isLinux)
                      _buildOpenDatabaseFolder(context, width),
                  ],
                ),
                _buildSection(
                  context,
                  title: l10n.developer,
                  children: [
                    _buildDeveloperModeSwitcher(context, width),
                    if (AppSettings().developerModeEnabled) ...[
                      _buildDecodeAsn1Switcher(context, width),
                      _buildLogConsoleSwitcher(context, width),
                      _buildLogsLink(context, width),
                    ],
                  ],
                ),
                _buildSection(
                  context,
                  title: l10n.about,
                  children: [
                    _buildVersionTile(context, width),
                    _buildUpdateCheckSwitcher(context, width),
                  ],
                ),
              ];

              return MasonryGridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: colCount,
                mainAxisSpacing: 32,
                crossAxisSpacing: 32,
                itemCount: allSections.length,
                itemBuilder: (context, index) {
                  return allSections[index];
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
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                letterSpacing: 2.0,
              ),
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
                    RepaintBoundary(child: children[i]),
                    if (i < children.length - 1) _buildDivider(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      context,
      title: l10n.notifications,
      children: [
        if (AppSettings().developerModeEnabled)
          _buildResponsiveTile(
            context,
            screenWidth: screenWidth,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: Colors.blue,
              ),
            ),
            title: l10n.notificationSettings,
            subtitle: l10n.notificationSettingsSubtitle,
            child: Icon(
              Icons.chevron_right,
              color: AppTheme.onSurfaceVerySubtle(context),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsPage(),
              ),
            ),
          ),
        _buildResponsiveTile(
          context,
          screenWidth: screenWidth,
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 20,
              color: Colors.blueAccent,
            ),
          ),
          title: l10n.notificationHistory,
          subtitle: l10n.notificationHistorySubtitle,
          child: Icon(
            Icons.chevron_right,
            color: AppTheme.onSurfaceVerySubtle(context),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationHistoryPage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsAndRemindersLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      context,
      title: l10n.tagsAndReminders,
      children: [
        _buildResponsiveTile(
          context,
          screenWidth: screenWidth,
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.label_outline_rounded,
              size: 20,
              color: Colors.blue,
            ),
          ),
          title: l10n.tagsAndReminders,
          subtitle: l10n.manageTagsAndRemindersSubtitle,
          child: Icon(
            Icons.chevron_right,
            color: AppTheme.onSurfaceVerySubtle(context),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TagsAndRemindersPage(),
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

  Widget _buildLanguageSelector(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, String>> languages = [
      {'code': 'null', 'name': l10n.systemLanguage},
      {'code': 'en', 'name': 'English'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'zh', 'name': '简体中文'},
      {'code': 'zh_TW', 'name': '繁體中文'},
    ];

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.language, size: 20, color: Colors.purple),
      ),
      title: l10n.language,
      child: _buildAdaptiveDropdown<String>(
        context: context,
        value: settings.locale ?? 'null',
        items: languages
            .map(
              (lang) => DropdownMenuItem(
                value: lang['code']!,
                child: Text(lang['name']!),
              ),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            settings.setLocale(newValue == 'null' ? null : newValue);
          }
        },
      ),
    );
  }

  Widget _buildAdbBridgeTile(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.usb_rounded, size: 20, color: Colors.blueGrey),
      ),
      title: l10n.adbBridgeTitle,
      subtitle: l10n.adbBridgeSubtitle,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdbBridgeConnectPage()),
      ),
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
    );
  }

  Widget _buildOtBridgeHintTile(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final subtitle = settings.nbridgeProviderAvailable
        ? 'Root detected. OTBridge is available for Telephony support and OMAPI ARA-M bypass.'
        : 'Root detected. OTBridge can be used to enable Telephony support and bypass OMAPI ARA-M restrictions.';

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_outlined, size: 20, color: Colors.green),
      ),
      title: 'OTBridge',
      subtitle: subtitle,
      child: Icon(
        settings.nbridgeProviderAvailable
            ? Icons.check_circle_outline
            : Icons.info_outline,
        color: settings.nbridgeProviderAvailable
            ? Colors.green
            : AppTheme.onSurfaceVerySubtle(context),
      ),
    );
  }

  Widget _buildThemeSwitcher(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    IconData getThemeIcon(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system:
          return Icons.brightness_auto_rounded;
        case ThemeMode.light:
          return Icons.light_mode;
        case ThemeMode.dark:
          return Icons.dark_mode;
      }
    }

    Color getThemeColor(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system:
          return Colors.blue;
        case ThemeMode.light:
          return Colors.orange;
        case ThemeMode.dark:
          return Colors.amber;
      }
    }

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: getThemeColor(settings.themeMode).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getThemeIcon(settings.themeMode),
          size: 20,
          color: getThemeColor(settings.themeMode),
        ),
      ),
      title: l10n.darkMode,
      child: _buildAdaptiveDropdown<ThemeMode>(
        context: context,
        value: settings.themeMode,
        items: [
          DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
          DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
          DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
        ],
        onChanged: (mode) {
          if (mode != null) settings.setThemeMode(mode);
        },
      ),
      onTap: () => settings.toggleDarkMode(),
    );
  }

  // ignore: unused_element
  Widget _buildThemeTypeSwitcher(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.color_lens_outlined,
          size: 20,
          color: Colors.indigo,
        ),
      ),
      title: l10n.themeStyle,
      subtitle: l10n.themeStyleSubtitle,
      child: _buildAdaptiveDropdown<AppThemeType>(
        context: context,
        value: settings.themeType,
        items: [
          DropdownMenuItem(
            value: AppThemeType.custom,
            child: Text(l10n.customDesign),
          ),
          DropdownMenuItem(
            value: AppThemeType.stock,
            child: Text(l10n.stockMD3),
          ),
        ],
        onChanged: (type) {
          if (type != null) settings.setThemeType(type);
        },
      ),
    );
  }

  Widget _buildLoadProfileIconsSwitcher(
    BuildContext context,
    double screenWidth,
  ) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.image_rounded, size: 20, color: Colors.orange),
      ),
      title: l10n.loadProfileIcons,
      subtitle: l10n.loadProfileIconsSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.loadProfileIcons,
        (v) => settings.setLoadProfileIcons(v),
      ),
      onTap: () => settings.setLoadProfileIcons(!settings.loadProfileIcons),
    );
  }

  Widget _buildRspProxyTile(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final proxyConfig = settings.rspProxyConfig;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.hub_outlined, size: 20, color: Colors.teal),
      ),
      title: 'RSP proxy',
      subtitle: proxyConfig.displayLabel,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => const _RspProxyDialog(),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildForceDeviceDropdownSwitcher(
    BuildContext context,
    double screenWidth,
  ) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_drop_down_circle_outlined,
          size: 20,
          color: Colors.blue,
        ),
      ),
      title: l10n.forceDeviceDropdown,
      subtitle: l10n.forceDeviceDropdownSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.forceDeviceDropdown,
        (v) => settings.setForceDeviceDropdown(v),
      ),
      onTap: () =>
          settings.setForceDeviceDropdown(!settings.forceDeviceDropdown),
    );
  }

  // ignore: unused_element
  Widget _buildNotificationHistoryLink(
    BuildContext context,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
      child: _buildResponsiveTile(
        context,
        screenWidth: screenWidth,
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.history, size: 20, color: Colors.blueAccent),
        ),
        title: l10n.notificationHistory,
        subtitle: l10n.notificationHistorySubtitle,
        child: Icon(
          Icons.chevron_right,
          color: AppTheme.onSurfaceVerySubtle(context),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationHistoryPage(),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ), // Reuse styles
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

  Widget _buildMssSlider(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.settings_ethernet,
          size: 20,
          color: Colors.deepPurple,
        ),
      ),
      title: l10n.apduMaxSegmentSize,
      subtitle: "${l10n.apduMaxSegmentSizeSubtitle} (${settings.mss})",
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _MssSliderDialog(settings: settings),
        );
      },
    );
  }

  Widget _buildDisableRefreshFlagsSwitcher(
    BuildContext context,
    double screenWidth,
  ) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.power_settings_new,
          size: 20,
          color: Colors.redAccent,
        ),
      ),
      title: l10n.disableRefreshFlags,
      subtitle: l10n.disableRefreshFlagsSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.disableRefreshFlags,
        (v) => settings.setDisableRefreshFlags(v),
      ),
      onTap: () =>
          settings.setDisableRefreshFlags(!settings.disableRefreshFlags),
    );
  }

  // ignore: unused_element
  Widget _buildEstimateProfileSizeSwitcher(
    BuildContext context,
    double screenWidth,
  ) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.analytics_outlined,
          size: 20,
          color: Colors.amber,
        ),
      ),
      title: l10n.estimateProfileSize,
      subtitle: l10n.estimateProfileSizeSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.estimateProfileSize,
        (v) => settings.setEstimateProfileSize(v),
      ),
      onTap: () =>
          settings.setEstimateProfileSize(!settings.estimateProfileSize),
    );
  }

  // ignore: unused_element
  Widget _buildSizeUnitSelector(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    final Map<String, String> options = {
      "settings_item_unit_b": "Bytes",
      "settings_item_unit_kb": "kB (1,000 Bytes)",
      "settings_item_unit_kib": "kiB (1,024 Bytes)",
      "settings_item_unit_adaptive_si": "B / kB Adaptive",
      "settings_item_unit_adaptive_bi": "B / kiB Adaptive",
    };

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.data_usage_rounded, size: 20, color: Colors.blueGrey),
      ),
      title: l10n.sizeDisplayUnit,
      subtitle: l10n.sizeDisplayUnitSubtitle,
      child: _buildAdaptiveDropdown<String>(
        context: context,
        value: settings.sizeUnit,
        items: options.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            settings.setSizeUnit(newValue);
          }
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPhoneFormatSelector(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    final Map<PhoneFormatStrategy, String> options = {
      PhoneFormatStrategy.internationalOnly: "E.164 Int'l Only",
      PhoneFormatStrategy.internationalAndMobile: "Int'l & Mobile",
      PhoneFormatStrategy.internationalAndAll: "Int'l & National",
      PhoneFormatStrategy.off: "Off",
    };

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.phone_iphone_rounded, size: 20, color: Colors.green),
      ),
      title: l10n.phoneFormat,
      subtitle: l10n.phoneFormatSubtitle,
      child: _buildAdaptiveDropdown<PhoneFormatStrategy>(
        context: context,
        value: settings.phoneFormatStrategy,
        items: options.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            settings.setPhoneFormatStrategy(newValue);
          }
        },
      ),
    );
  }

  Widget _buildDeveloperModeSwitcher(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.terminal_rounded,
          size: 20,
          color: Colors.purple,
        ),
      ),
      title: l10n.developerMode,
      subtitle: l10n.developerModeSubtitle,
      child: _buildCustomSwitch(
        context,
        settings.developerModeEnabled,
        (v) => settings.setDeveloperModeEnabled(v),
      ),
      onTap: () =>
          settings.setDeveloperModeEnabled(!settings.developerModeEnabled),
    );
  }

  Widget _buildExportDatabase(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.save_alt_rounded,
          size: 20,
          color: Colors.blueGrey,
        ),
      ),
      title: l10n.exportDatabase,
      subtitle: l10n.exportDatabaseSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () async {
        try {
          final bytes = await DatabaseService().exportDatabase();
          final String timestamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final fileName = 'kasutera_backup_$timestamp.db';
          final outputPath = await FilePicker.platform.saveFile(
            dialogTitle: l10n.exportDatabase,
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: const ['db'],
            bytes: PlatformX.isMobile ? bytes : null,
          );

          if (outputPath != null) {
            // Mobile file providers consume [bytes] themselves. Desktop
            // pickers return a normal path and leave writing to the app.
            if (!PlatformX.isMobile) {
              await io.File(outputPath).writeAsBytes(bytes, flush: true);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.exportSuccess(outputPath))),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.exportFailed(e.toString()))),
            );
          }
        }
      },
    );
  }

  Widget _buildImportDatabase(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.file_download_outlined,
          size: 20,
          color: Colors.blue,
        ),
      ),
      title: l10n.importDatabase,
      subtitle: l10n.importDatabaseSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            dialogTitle: l10n.importDatabaseDialogTitle,
            withData: PlatformX.isMobile,
          );

          if (result != null) {
            final selectedFile = result.files.single;
            if (context.mounted) {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.importDatabaseTitle),
                  content: Text(l10n.importDatabaseContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.importAction),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                if (PlatformX.isMobile) {
                  final selectedPath = selectedFile.path;
                  final bytes =
                      selectedFile.bytes ??
                      (selectedPath == null
                          ? throw StateError(
                              'The selected file has no readable data.',
                            )
                          : await io.File(selectedPath).readAsBytes());
                  await DatabaseService().importDatabaseBytes(bytes);
                } else {
                  final selectedPath = selectedFile.path;
                  if (selectedPath == null) {
                    throw StateError('The selected file has no readable path.');
                  }
                  await DatabaseService().importDatabase(selectedPath);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.importSuccess)));
                }
              }
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.importFailed(e.toString()))),
            );
          }
        }
      },
    );
  }

  Widget _buildResetDatabase(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_forever_outlined,
          size: 20,
          color: Colors.red,
        ),
      ),
      title: l10n.resetDatabase,
      subtitle: l10n.resetDatabaseSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () async {
        if (context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.resetDatabaseTitle),
              content: Text(l10n.resetDatabaseContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.resetDatabase),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await DatabaseService().resetDatabase();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.success)));
            }
          }
        }
      },
    );
  }

  Widget _buildOpenDatabaseFolder(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.folder_open_rounded,
          size: 20,
          color: Colors.green,
        ),
      ),
      title: l10n.openDatabaseFolder,
      subtitle: l10n.openDatabaseFolderSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () async {
        try {
          final dbPath = await DatabaseService().getDatabasePath();
          final dbFile = io.File(dbPath);

          if (!dbFile.existsSync()) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Database file not found.")),
              );
            }
            return;
          }

          // Get the directory containing the database file
          final dbDirectory = path.dirname(dbPath);
          final directory = io.Directory(dbDirectory);

          if (!directory.existsSync()) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Database folder not found.")),
              );
            }
            return;
          }

          // Open folder using platform-specific commands
          if (PlatformX.isWindows) {
            await io.Process.run('explorer.exe', [
              dbDirectory,
            ], runInShell: true);
          } else if (PlatformX.isMacOS) {
            await io.Process.run('open', [dbDirectory], runInShell: false);
          } else if (PlatformX.isLinux) {
            await io.Process.run('xdg-open', [dbDirectory], runInShell: false);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to open database folder: $e")),
            );
          }
        }
      },
    );
  }

  Widget _buildManageAidsLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.nfc, size: 20, color: Colors.teal),
      ),
      title: l10n.manageIsdR,
      subtitle: l10n.manageIsdRSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AidSettingsPage()),
      ),
    );
  }

  Widget _buildStatsLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.analytics_outlined,
          size: 20,
          color: Colors.teal,
        ),
      ),
      title: l10n.nekokoCloud,
      subtitle: l10n.nekokoCloudSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatsSettingsPage()),
      ),
    );
  }

  Widget _buildDecodeAsn1Switcher(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.code, size: 20, color: Colors.green),
      ),
      title: l10n.decodeAsn1,
      subtitle: l10n.decodeAsn1Subtitle,
      child: _buildCustomSwitch(
        context,
        settings.decodeAsn1,
        (v) => settings.setDecodeAsn1(v),
      ),
      onTap: () => settings.setDecodeAsn1(!settings.decodeAsn1),
    );
  }

  Widget _buildLogConsoleSwitcher(BuildContext context, double screenWidth) {
    final settings = AppSettings();

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.terminal, size: 20, color: Colors.blueGrey),
      ),
      title: 'Log console',
      subtitle: 'Show a live log tail under the profile list',
      child: _buildCustomSwitch(
        context,
        settings.showLogConsole,
        (v) => settings.setShowLogConsole(v),
      ),
      onTap: () => settings.setShowLogConsole(!settings.showLogConsole),
    );
  }

  Widget _buildLogsLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.brown.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.receipt_long, size: 20, color: Colors.brown),
      ),
      title: l10n.viewAppLogs,
      subtitle: l10n.viewAppLogsSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AppLogsPage()),
      ),
    );
  }

  Widget _buildReaderTypesLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.devices_rounded,
          size: 20,
          color: Colors.indigo,
        ),
      ),
      title: l10n.readerTypes,
      subtitle: l10n.readerTypesSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReaderTypesSettingsPage(),
        ),
      ),
    );
  }

  Widget _buildBleDevicesLink(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.bluetooth_connected_rounded,
          size: 20,
          color: Colors.indigo,
        ),
      ),
      title: l10n.savedBleDevices,
      subtitle: l10n.savedBleDevicesSubtitle,
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BleDevicesSettingsPage()),
      ),
    );
  }

  Widget _buildPluginToggle(
    BuildContext context,
    double screenWidth,
    PluginSettingsToggle toggle,
  ) {
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: toggle.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(toggle.icon, size: 20, color: toggle.color),
      ),
      title: toggle.title,
      subtitle: toggle.subtitle,
      child: _buildCustomSwitch(
        context,
        toggle.value,
        (value) => _applyPluginToggle(context, toggle, value),
      ),
      onTap: () => _applyPluginToggle(context, toggle, !toggle.value),
    );
  }

  Future<void> _applyPluginToggle(
    BuildContext context,
    PluginSettingsToggle toggle,
    bool enabled,
  ) async {
    // The page rebuilds from the settings the plugin changes.
    await toggle.onChanged(context, enabled);
  }

  Widget _buildUpdateCheckSwitcher(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.update, size: 20, color: Colors.blue),
      ),
      title: l10n.checkUpdates,
      subtitle: l10n.checkUpdatesSubtitle,
      child: _buildCustomSwitch(
        context,
        AppSettings().enableUpdateCheck,
        (val) => AppSettings().setEnableUpdateCheck(val),
      ),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkUpdates),
            duration: const Duration(seconds: 1),
          ),
        );
        final update = await UpdateService().checkForUpdates();
        if (context.mounted) {
          if (update != null) {
            showUpdateDialog(context, update);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.noUpdatesFound)));
          }
        }
      },
    );
  }

  Widget _buildImeiSelector(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<String>(
      future: settings.getDisplayedImeiDigits(),
      builder: (context, snapshot) {
        final imeiDigits = snapshot.data ?? '........';

        return _buildResponsiveTile(
          context,
          screenWidth: screenWidth,
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 20,
              color: Colors.blueGrey,
            ),
          ),
          title: l10n.deviceImei,
          subtitle: l10n.deviceImeiSubtitle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              imeiDigits,
              style: AppTheme.mono(
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          onTap: () => _showImeiEditDialog(context, imeiDigits),
        );
      },
    );
  }

  void _showImeiEditDialog(BuildContext context, String currentTac) {
    final controller = TextEditingController(text: currentTac);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editDeviceImei),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.editDeviceImeiInfo,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.imeiDigits,
                hintText: defaultDeviceTac,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    controller.text = defaultDeviceTac;
                  },
                ),
              ),
              style: AppTheme.mono(),
              maxLength: 15,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await AppSettings().setImeiString(controller.text);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context, double screenWidth) {
    final settings = AppSettings();
    final l10n = AppLocalizations.of(context)!;

    return _buildResponsiveTile(
      context,
      screenWidth: screenWidth,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline, size: 20, color: Colors.blue),
      ),
      title: "${l10n.version} / ${l10n.build}",
      subtitle: "${settings.version} build ${settings.buildNumber}",
      child: Icon(
        Icons.chevron_right,
        color: AppTheme.onSurfaceVerySubtle(context),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Build Information"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Version: ${settings.version}"),
                Text("Build: ${settings.buildNumber}"),
                const SizedBox(height: 8),
                Text(
                  "Commit: ${settings.commitHash}",
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RspProxyDialog extends StatefulWidget {
  const _RspProxyDialog();

  @override
  State<_RspProxyDialog> createState() => _RspProxyDialogState();
}

class _RspProxyDialogState extends State<_RspProxyDialog> {
  late RspProxyMode _mode;
  late String _forwardProtocol;
  late final TextEditingController _forwardHostController;
  late final TextEditingController _forwardPortController;
  late final TextEditingController _reversePrefixController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final config = AppSettings().rspProxyConfig;
    _mode = config.mode;
    _forwardProtocol = config.forwardProtocol;
    _forwardHostController = TextEditingController(text: config.forwardHost);
    _forwardPortController = TextEditingController(
      text: config.forwardPort?.toString() ?? '',
    );
    _reversePrefixController = TextEditingController(
      text: config.reverseUrlPrefix,
    );
  }

  @override
  void dispose() {
    _forwardHostController.dispose();
    _forwardPortController.dispose();
    _reversePrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('RSP proxy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<RspProxyMode>(
              segments: const [
                ButtonSegment(
                  value: RspProxyMode.direct,
                  icon: Icon(Icons.public),
                  label: Text('Direct'),
                ),
                ButtonSegment(
                  value: RspProxyMode.forward,
                  icon: Icon(Icons.route_outlined),
                  label: Text('Forward'),
                ),
                ButtonSegment(
                  value: RspProxyMode.reverse,
                  icon: Icon(Icons.alt_route),
                  label: Text('Reverse'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selected) {
                setState(() {
                  _mode = selected.first;
                  _errorText = null;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_mode == RspProxyMode.forward) ...[
              DropdownButtonFormField<String>(
                initialValue: _forwardProtocol,
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'http', child: Text('HTTP')),
                  DropdownMenuItem(value: 'socks', child: Text('SOCKS')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _forwardProtocol = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _forwardHostController,
                decoration: const InputDecoration(
                  labelText: 'Proxy host',
                  hintText: '127.0.0.1',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _forwardPortController,
                decoration: const InputDecoration(
                  labelText: 'Proxy port',
                  hintText: '8080',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ] else if (_mode == RspProxyMode.reverse) ...[
              TextField(
                controller: _reversePrefixController,
                decoration: const InputDecoration(
                  labelText: 'URL prefix',
                  hintText: 'https://proxy.example/rsp',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Text(
                'Requests become: prefix / RSP host / gsma/rsp2/es9plus / endpoint',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceSubtle(context),
                ),
              ),
            ] else
              Text(
                'RSP requests connect directly to the SM-DP+ or SM-DS host.',
                style: TextStyle(color: AppTheme.onSurfaceSubtle(context)),
              ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _save() async {
    final forwardHost = _forwardHostController.text.trim();
    final forwardPort = RspProxyConfig.parsePort(_forwardPortController.text);
    final reversePrefix = _reversePrefixController.text.trim();

    if (_mode == RspProxyMode.forward) {
      if (forwardHost.isEmpty) {
        setState(() => _errorText = 'Proxy host is required.');
        return;
      }
      if (forwardPort == null) {
        setState(() => _errorText = 'Proxy port must be 1-65535.');
        return;
      }
    }

    if (_mode == RspProxyMode.reverse) {
      final uri = Uri.tryParse(reversePrefix);
      final valid =
          uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
      if (!valid) {
        setState(() => _errorText = 'Enter an absolute HTTP or HTTPS URL.');
        return;
      }
    }

    await AppSettings().setRspProxyConfig(
      RspProxyConfig(
        mode: _mode,
        forwardProtocol: _forwardProtocol,
        forwardHost: forwardHost,
        forwardPort: forwardPort,
        reverseUrlPrefix: reversePrefix,
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }
}

class _MssSliderDialog extends StatefulWidget {
  final AppSettings settings;
  const _MssSliderDialog({required this.settings});

  @override
  State<_MssSliderDialog> createState() => _MssSliderDialogState();
}

class _MssSliderDialogState extends State<_MssSliderDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.settings.mss.clamp(AppSettings.minMss, AppSettings.maxMss);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.apduMaxSegmentSize),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.apduMaxSegmentSizeSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$_value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _value.toDouble(),
            min: AppSettings.minMss.toDouble(),
            max: AppSettings.maxMss.toDouble(),
            divisions: AppSettings.maxMss - AppSettings.minMss,
            onChanged: (v) {
              setState(() {
                _value = v.toInt();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.settings.setMss(_value);
            Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
