import 'package:flutter/material.dart';

/// DESIGN.md contradictions resolved for Phase 1:
/// - YAML tokens win for primary/background/ink: #0A4096, #2F59AF, #F9F9FF, #121B2E.
/// - Prose “Primary Blue #2F59AF” maps to [primaryContainer] (actions/nav).
/// - Prose Surface #F7F9FC is not used; background stays #F9F9FF.
/// - Lime (#BBD562) is for success washes only; text on lime uses dark ink;
///   positive text on white uses [successOnLight] (#7DAA35), never lime-on-white.
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF0A4096);
  static const primaryContainer = Color(0xFF2F59AF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const background = Color(0xFFF9F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFE9EDFF);
  static const onSurface = Color(0xFF121B2E);
  static const onSurfaceVariant = Color(0xFF434652);
  static const outline = Color(0xFF747783);
  static const outlineVariant = Color(0xFFC3C6D4);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const successWash = Color(0xFFBBD562);
  static const successOnLight = Color(0xFF7DAA35);
  static const warning = Color(0xFF8B5A00);
  static const warningWash = Color(0xFFFFEFD0);

  /// Reference tertiary / lime system (status dots, switches).
  static const tertiary = Color(0xFF3C4B00);
  static const tertiaryContainer = Color(0xFF516400);
  static const tertiaryFixed = Color(0xFFD3EE78);
  static const tertiaryFixedDim = Color(0xFFB7D15F);
  static const secondary = Color(0xFF4658AC);
  static const onPrimaryContainer = Color(0xFFC7D5FF);
  static const primaryFixed = Color(0xFFD9E2FF);
  static const onPrimaryFixed = Color(0xFF001946);
  static const surfaceContainerLow = Color(0xFFF1F3FF);
  static const surfaceContainerHigh = Color(0xFFE1E8FF);
  static const surfaceContainerHighest = Color(0xFFD9E2FC);
  static const surfaceVariant = Color(0xFFD9E2FC);
  static const surfaceDim = Color(0xFFD1DAF4);
  static const onTertiaryFixed = Color(0xFF171E00);
  static const onTertiaryFixedVariant = Color(0xFF3D4C00);
  static const secondaryContainer = Color(0xFF94A6FF);
  static const onSecondaryContainer = Color(0xFF24388B);

  /// Bottom-nav active pill (parity matrix decision D-A1).
  static const navPill = primaryContainer;
  static const onNavPill = onPrimaryContainer;

  /// Concept V1 dock: pale capsule, deep-blue active, muted handle.
  static const navCapsule = Color(0xFFE8EEFF);
  static const navHandle = Color(0xFF8A93A8);
  static const navInactive = Color(0xFF6B7280);
  static const navBorder = Color(0x14C3C6D4);
}

/// Reference `shadow-card`: 4 % black, 8 px blur, 2 px offset.
const merchantCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];

/// Spacing / radius tokens from MerchantScreens Tailwind config.
class MerchantLayout {
  const MerchantLayout._();

  static const gutter = 16.0;
  static const stackSm = 4.0;
  static const stackMd = 12.0;
  static const stackLg = 24.0;
  static const radiusLg = 8.0;
  static const radiusXl = 12.0;
  static const radiusCard = 12.0;
  static const headerHeight = 56.0;
  static const stickyActionHeight = 52.0;
  static const thumbSize = 64.0;
  static const iconCircle = 40.0;
}

/// Concept V1 merchant root-tab dock. Colors, sizes and motion live here
/// so screens do not invent navigation chrome.
class MerchantNavTokens {
  const MerchantNavTokens._();

  static const dockHeight = 72.0;
  static const dockMarginH = 16.0;
  static const dockMarginV = 8.0;
  static const dockRadius = 24.0;
  static const capsuleRadius = 16.0;
  static const handleWidth = 32.0;
  static const handleHeight = 4.0;
  static const minTarget = 48.0;
  static const hideThreshold = 48.0;
  static const tabFade = 0.10;

  static const tabTransition = Duration(milliseconds: 220);
  static const hideDuration = Duration(milliseconds: 200);
  static const selectionDuration = Duration(milliseconds: 180);

  static const tabCurve = Curves.easeOutCubic;
  static const hideCurve = Curves.easeOutCubic;

  static const dockBorder = BorderSide(color: Color(0x1FC3C6D4));
  static const dockShadow = [
    BoxShadow(color: Color(0x140A4096), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

class AppTheme {
  const AppTheme._();

  static const latinFont = 'Inter';
  static const arabicFont = 'NotoSansArabic';

  static ThemeData light({Locale? locale}) {
    final isArabic = locale?.languageCode == 'ar';
    final family = isArabic ? arabicFont : latinFont;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: family,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final textTheme = base.textTheme.apply(
      fontFamily: family,
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    );
    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: isArabic ? 1.35 : 1.25,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: isArabic ? 1.4 : 1.33,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurfaceVariant,
        elevation: 1,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: MerchantLayout.headerHeight,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.primary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        // Elevation shadows rasterize as hard black outlines in widget
        // captures — keep the FAB flat.
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
