import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../settings/app_settings.dart';

const Color kPrimaryColor = Color(0xFF07ACE9);
const Color kPrimaryColor2 = Color(0xFF22D0F7);
const Color kErrorColor = Color(0xFFE53935);
const Color kSuccessColor = Color(0xFF43A047);

class AppTheme {
  static ThemeData theme(bool isDark, [AppThemeType? type]) {
    final themeType = type ?? AppSettings().themeType;

    if (themeType == AppThemeType.stock) {
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ),
        // Eliminating borders for MD3 stock theme as requested
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
          ),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            side: BorderSide.none,
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Non-MD3 / Custom Premium Theme Configuration
    // -------------------------------------------------------------------------
    // This section defines the custom theme that fully customizes colors,
    // borders, and transparency effects beyond Material 3 defaults.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: isDark
          ? const Color(0xFF64B5F6)
          : kPrimaryColor, // Lighter blue for dark mode
      secondary: const Color(0xFF8B5CF6),
      error: kErrorColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: isDark ? const Color(0xFF0F172A) : Colors.white,
      onSurface: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
      surfaceContainerHighest: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFF1F3F4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      dividerColor: isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : Colors.black.withValues(alpha: 0.05),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8F9FA),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kPrimaryColor;
          return isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      textTheme: AppTheme.defaultFontTextTheme(
        // We need to apply the base text theme to ensure proper defaults
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),

      // Global component themes
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTheme.defaultFont(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTheme.defaultFont(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.3)
                : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          textStyle: AppTheme.defaultFont(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTheme.defaultFont(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark
              ? const Color(0xFF020617)
              : const Color(0xFFF8F9FA),
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTheme.defaultFont(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTheme.defaultFont(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
          height: 1.5,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
              : BorderSide.none,
        ),
        textStyle: AppTheme.defaultFont(
          fontSize: 14,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTheme.defaultFont(
          fontSize: 14,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isDark
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                  : BorderSide.none,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isDark
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // Semantic helpers
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  // Custom semantic colors that bridge Material 3 and our design
  static Color surfaceSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.03);

  static Color onSurfaceSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.6)
      : Colors.black.withValues(alpha: 0.5);

  static Color onSurfaceVerySubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.4)
      : Colors.black.withValues(alpha: 0.35);

  static Color surfaceVerySubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.02)
      : Colors.black.withValues(alpha: 0.015);

  static Color cardBackground(BuildContext context) {
    if (AppSettings().themeType == AppThemeType.stock) {
      return Theme.of(context).colorScheme.surfaceContainerLow;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B2436)
        : Colors.white;
  }

  static BoxDecoration highlightedCardDecoration(
    BuildContext context, {
    bool enabled = false,
  }) {
    final theme = Theme.of(context);
    final isStock = AppSettings().themeType == AppThemeType.stock;

    if (isStock) {
      // MD3: No visible borders, rely on tonal elevation and colors
      return BoxDecoration(
        color: enabled
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 0),
      );
    }

    // Non-MD3 / Custom Theme: Uses explicit borders and transparency effects
    return BoxDecoration(
      color: enabled
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: enabled
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.dividerColor.withValues(alpha: 0.1),
        width: enabled ? 2 : 1,
      ),
      boxShadow: [
        if (!enabled)
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  static BoxDecoration bannerDecoration(BuildContext context) {
    final theme = Theme.of(context);
    if (AppSettings().themeType == AppThemeType.stock) {
      // MD3: Filled container, no border
      return BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent, width: 0),
      );
    }

    // Non-MD3 / Custom Theme
    return BoxDecoration(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  static BoxDecoration badgeDecoration(BuildContext context, Color baseColor) {
    if (AppSettings().themeType == AppThemeType.stock) {
      // MD3: Tonal container, no border (like FilterChip/AssistChip)
      return BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent, width: 0),
      );
    }

    // Non-MD3 / Custom Theme
    return BoxDecoration(
      color: baseColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: baseColor.withValues(alpha: 0.3)),
    );
  }

  static TextStyle badgeTextStyle(BuildContext context, Color baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? baseColor : Color.lerp(baseColor, Colors.black, 0.4),
    );
  }

  static Color bluetoothIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.blue[300]!
      : Colors.blue[600]!;

  static Color simCardIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.green[300]!
      : Colors.green[600]!;

  static Color smdpAddress(BuildContext context) {
    if (AppSettings().themeType == AppThemeType.stock) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA) // Blue 400
        : const Color(0xFF2563EB); // Blue 600
  }

  static Color matchingId(BuildContext context) {
    if (AppSettings().themeType == AppThemeType.stock) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4ADE80) // Green 400
        : const Color(0xFF16A34A); // Green 600
  }

  static Color smdpOid(BuildContext context) {
    if (AppSettings().themeType == AppThemeType.stock) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2DD4BF) // Teal 400
        : const Color(0xFF0D9488); // Teal 600
  }

  static Color confirmationCode(BuildContext context) {
    if (AppSettings().themeType == AppThemeType.stock) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFB923C) // Orange 400
        : const Color(0xFFEA580C); // Orange 600
  }

  static TextStyle defaultFont({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.googleSans(
      textStyle: textStyle,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme defaultFontTextTheme(TextTheme base) {
    return GoogleFonts.googleSansTextTheme(base);
  }

  static TextStyle mono([TextStyle? base]) =>
      GoogleFonts.ibmPlexMono(textStyle: base);
}
