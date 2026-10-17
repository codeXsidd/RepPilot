import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryBlue = Color(0xFF448AFF);
  static const Color primaryBlueLight = Color(0xFF5C9CFF);

  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkSurface = Color(0xFF151518);
  static const Color darkCard = Color(0xFF1C1C21);
  static const Color darkCardHigh = Color(0xFF232329);
  static const Color darkBorder = Color(0xFF2A2A32);

  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0F2);
  static const Color lightBorder = Color(0xFFE0E0E4);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  static const Color textPrimary = Color(0xFFF0F0F2);
  static const Color textSecondary = Color(0xFF9E9EA8);
  static const Color textTertiary = Color(0xFF6B6B75);

  static const Color textPrimaryLight = Color(0xFF1A1A1E);
  static const Color textSecondaryLight = Color(0xFF5C5C66);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double pagePadding = 16;
  static const double cardPadding = 16;
  static const double sectionGap = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const double buttonHeight = 48;
  static const double buttonHeightSm = 36;
  static const double iconSizeSm = 18;
  static const double iconSizeMd = 22;
  static const double iconSizeLg = 28;
}

class AppTheme {
  static ThemeData light() {
    const primary = AppColors.primaryBlue;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E4FF),
      onPrimaryContainer: const Color(0xFF1A3A6B),
      secondary: const Color(0xFF546E7A),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCFD8DC),
      onSecondaryContainer: const Color(0xFF1B2D35),
      tertiary: const Color(0xFF7C5CBF),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFEDE4FF),
      onTertiaryContainer: const Color(0xFF2D1A5E),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: AppColors.lightBg,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.lightBorder,
      outlineVariant: const Color(0xFFD0D0D6),
      surfaceContainerHighest: AppColors.lightCard,
      surfaceContainerHigh: const Color(0xFFE8E8EC),
      surfaceContainerLow: AppColors.lightSurface,
      inverseSurface: const Color(0xFF2E2E34),
      onInverseSurface: const Color(0xFFF0F0F2),
    );
    return _build(colorScheme);
  }

  static ThemeData dark() {
    const primary = AppColors.primaryBlue;
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1A3366),
      onPrimaryContainer: const Color(0xFFD6E4FF),
      secondary: const Color(0xFF8EACBB),
      onSecondary: const Color(0xFF1B2D35),
      secondaryContainer: const Color(0xFF2B3E48),
      onSecondaryContainer: const Color(0xFFCFD8DC),
      tertiary: const Color(0xFFB49AE0),
      onTertiary: const Color(0xFF2D1A5E),
      tertiaryContainer: const Color(0xFF3D2E66),
      onTertiaryContainer: const Color(0xFFEDE4FF),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF5C1A1A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AppColors.darkBg,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: const Color(0xFF35353D),
      surfaceContainerHighest: AppColors.darkCardHigh,
      surfaceContainerHigh: AppColors.darkCard,
      surfaceContainerLow: AppColors.darkSurface,
      inverseSurface: const Color(0xFFE4E4E8),
      onInverseSurface: const Color(0xFF1A1A1E),
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final textTheme = ThemeData(colorScheme: cs).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: cs.outline.withValues(alpha: isDark ? 0.3 : 0.15),
          ),
        ),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCardHigh : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? cs.primary : cs.onSurfaceVariant,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 22);
          }
          return IconThemeData(color: cs.onSurfaceVariant, size: 22);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outline.withValues(alpha: isDark ? 0.2 : 0.12),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primary.withValues(alpha: 0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: cs.onSurfaceVariant, width: 1.5),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        elevation: 2,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: cs.primary,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outline.withValues(alpha: 0.1),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        color: isDark ? AppColors.darkCardHigh : AppColors.lightSurface,
      ),
    );
  }
}
