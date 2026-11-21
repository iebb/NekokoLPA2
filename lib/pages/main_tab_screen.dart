import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profiles_screen.dart';
import 'buy_page.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../settings/app_settings.dart';
import '../plugins/plugin_manager.dart';
import 'package:flutter/foundation.dart';
import '../utils/platform_adapter.dart';
import '../widgets/lazy_tab_body.dart';
import '../theme/adaptive_layout.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  final GlobalKey _pagesKey = GlobalKey(debugLabel: 'main_tab_pages');
  int _currentIndex = 0;
  bool _isHoveringTopBar = false;

  // Base pages that are always there or standard
  // We'll construct the active list in build or compute it.

  @override
  void initState() {
    super.initState();
    AppSettings().addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings().removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = AppSettings();
    // Determine if we should show standard buy tab

    final pluginTabs = PluginManager().appTabs;
    final tabEntries = <_MainTabEntry>[
      _MainTabEntry(
        id: 'profiles',
        label: l10n.manage,
        icon: Icons.sim_card_outlined,
        activeIcon: Icons.sim_card,
        pageBuilder: (_) => const ProfilesScreen(),
      ),
      ...pluginTabs.map(
        (tab) => _MainTabEntry(
          id: 'plugin:${tab.id}',
          label: tab.label,
          icon: tab.icon,
          activeIcon: tab.activeIcon,
          pageBuilder: tab.builder,
        ),
      ),
    ];

    // Variant Tabs from Config
    if (settings.enableBrowser) {
      for (final tabConfig in settings.variantTabs) {
        if (!tabConfig.isEnabled) continue;
        if (!settings.isOnline) continue;
        if (kIsWeb) continue;
        if (PlatformX.isWindows || PlatformX.isLinux) continue;

        tabEntries.add(
          _MainTabEntry(
            id: 'browser:${tabConfig.url}',
            label: tabConfig.label,
            icon: _resolveIcon(tabConfig.icon, false),
            activeIcon: _resolveIcon(tabConfig.icon, true),
            pageBuilder: (_) =>
                BuyPage(url: tabConfig.url, title: tabConfig.title),
          ),
        );
      }
    }

    if (_currentIndex >= tabEntries.length) _currentIndex = 0;
    final pages = IndexedStack(
      // Keeps every tab's state when the navigation style changes, such as
      // when an iPhone Duo is unfolded or a phone is rotated.
      key: _pagesKey,
      index: _currentIndex,
      children: List<Widget>.generate(tabEntries.length, (index) {
        final entry = tabEntries[index];
        return LazyTabBody(
          key: ValueKey(entry.id),
          active: index == _currentIndex,
          builder: entry.pageBuilder,
        );
      }, growable: false),
    );

    switch (_navigationStyle(context, tabEntries.length)) {
      case _NavigationStyle.none:
        return Scaffold(body: pages);
      case _NavigationStyle.bottomBar:
        return Scaffold(
          body: pages,
          bottomNavigationBar: _buildBottomBar(context, tabEntries),
        );
      case _NavigationStyle.rail:
        return Scaffold(body: _buildWithRail(context, tabEntries, pages));
      case _NavigationStyle.floatingBar:
        return Scaffold(
          body: Stack(
            children: [pages, _buildFloatingBar(context, tabEntries)],
          ),
        );
    }
  }

  _NavigationStyle _navigationStyle(BuildContext context, int tabCount) {
    if (tabCount < 2) return _NavigationStyle.none;
    if (WindowWidthClass.ofContext(context) == WindowWidthClass.compact) {
      return _NavigationStyle.bottomBar;
    }
    // Labels in the floating bar appear on hover, which touch cannot do.
    return PlatformX.isMobile
        ? _NavigationStyle.rail
        : _NavigationStyle.floatingBar;
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.selectionClick();
  }

  Widget _buildBottomBar(BuildContext context, List<_MainTabEntry> entries) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Expanded(
                      child: _buildBottomBarItem(context, entries[i], i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(
    BuildContext context,
    _MainTabEntry entry,
    int index,
  ) {
    final theme = Theme.of(context);
    final isActive = _currentIndex == index;
    final color = isActive
        ? theme.colorScheme.primary
        : AppTheme.onSurfaceSubtle(context);

    return Semantics(
      button: true,
      selected: isActive,
      label: entry.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => _selectTab(index),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? entry.activeIcon : entry.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A labelled rail beside the content, for touch screens of medium width
  /// and up: tablets, phones in landscape and the unfolded iPhone Duo.
  Widget _buildWithRail(
    BuildContext context,
    List<_MainTabEntry> entries,
    Widget pages,
  ) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = AppTheme.onSurfaceSubtle(context);

    final rail = Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        left: !isRtl,
        right: isRtl,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectTab,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -1,
            scrollable: true,
            backgroundColor: Colors.transparent,
            indicatorColor: selectedColor.withValues(alpha: 0.12),
            selectedIconTheme: IconThemeData(color: selectedColor, size: 24),
            unselectedIconTheme: IconThemeData(
              color: unselectedColor,
              size: 24,
            ),
            selectedLabelTextStyle: TextStyle(
              color: selectedColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: unselectedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            destinations: [
              for (final entry in entries)
                NavigationRailDestination(
                  icon: Icon(entry.icon),
                  selectedIcon: Icon(entry.activeIcon),
                  label: SizedBox(
                    width: 72,
                    child: Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        rail,
        VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: !isRtl,
            removeRight: isRtl,
            child: pages,
          ),
        ),
      ],
    );
  }

  /// A compact bar floating over the content for pointer devices, whose
  /// labels expand on hover.
  Widget _buildFloatingBar(BuildContext context, List<_MainTabEntry> entries) {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 4,
      left: 0,
      right: 0,
      child: Center(
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHoveringTopBar = true),
          onExit: (_) => setState(() => _isHoveringTopBar = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.9,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(entries.length, (index) {
                final bool isActive = _currentIndex == index;
                final entry = entries[index];
                final label = entry.label;
                final icon = isActive ? entry.activeIcon : entry.icon;

                return Semantics(
                  button: true,
                  selected: isActive,
                  label: label,
                  excludeSemantics: true,
                  child: Tooltip(
                    message: _isHoveringTopBar ? '' : label,
                    child: InkWell(
                      onTap: () => _selectTab(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: isActive
                            ? BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: isActive
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: _isHoveringTopBar
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 8),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: isActive
                                                ? theme.colorScheme.onPrimary
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: isActive
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String name, bool active) {
    switch (name) {
      case 'web':
        return active ? Icons.explore : Icons.explore_outlined;
      case 'shopping_cart':
        return active ? Icons.shopping_cart : Icons.shopping_cart_outlined;
      case 'language':
        return active ? Icons.language : Icons.language_outlined;
      case 'sim_card':
        return active ? Icons.sim_card : Icons.sim_card_outlined;
      case 'devices_other':
        return active ? Icons.devices_other : Icons.devices_other_outlined;
      default:
        return active ? Icons.circle : Icons.circle_outlined;
    }
  }
}

enum _NavigationStyle { none, bottomBar, rail, floatingBar }

class _MainTabEntry {
  const _MainTabEntry({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.pageBuilder,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final WidgetBuilder pageBuilder;
}
