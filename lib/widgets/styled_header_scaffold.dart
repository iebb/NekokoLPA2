import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A reusable scaffold with a stylized header for secondary pages
/// Automatically handles safe area padding for mobile devices, including the
/// side insets of a phone in landscape
class StyledHeaderScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget body;
  final bool showBackButton;
  final String? logoAsset;
  final List<Widget>? actions;
  final bool compact;
  final VoidCallback? onTitleTap;

  const StyledHeaderScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    required this.body,
    this.actions,
    this.showBackButton = true,
    this.logoAsset,
    this.compact = false,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safePadding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Custom Header with safe area padding
            Container(
              padding: EdgeInsets.fromLTRB(
                12 + safePadding.left,
                (compact ? 8 : 12) + safePadding.top,
                16 + safePadding.right,
                compact ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (logoAsset != null) ...[
                    Image.asset(logoAsset!, height: 24),
                    const SizedBox(width: 12),
                  ] else if (showBackButton) ...[
                    // Back button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(context),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppTheme.onSurfaceSubtle(context),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else
                    const SizedBox(width: 4),
                  // Title
                  Expanded(
                    child: GestureDetector(
                      onTap: onTitleTap,
                      behavior: HitTestBehavior.opaque,
                      child:
                          titleWidget ??
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Text(
                                  title!,
                                  style: TextStyle(
                                    fontSize: compact ? 16 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceSubtle(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                    ),
                  ),
                  // Optional actions
                  ...?actions,
                ],
              ),
            ),
            // Body content
            Expanded(
              // The header has taken the top inset.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: SafeArea(top: false, bottom: false, child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
