import 'package:flutter/material.dart';
import 'package:gravity_app/core/theme/app_colors.dart';
import 'package:gravity_app/core/theme/app_spacing.dart';
import 'package:gravity_app/core/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSansTamil', 'NotoSansDevanagari'],
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brandPrimary,
            brightness: Brightness.light,
          ).copyWith(
            primary: AppColors.brandPrimary,
            secondary: AppColors.brandSecondary,
            tertiary: AppColors.brandTertiary,
            surface: AppColors.lightSurface,
            surfaceContainerHighest: AppColors.lightSurfaceStrong,
          ),
      cardTheme: CardThemeData(
        color: AppColors.white.withValues(alpha: 0.68),
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.dialogTitleLight,
        contentTextStyle: AppTextStyles.dialogContentLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightSnackBackground,
        contentTextStyle: AppTextStyles.snackBarContent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: AppSpacing.buttonPadding,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: AppSpacing.buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          side: BorderSide(color: AppColors.black.withValues(alpha: 0.15)),
          padding: AppSpacing.buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          padding: AppSpacing.textButtonPadding,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSansTamil', 'NotoSansDevanagari'],
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brandPrimary,
            brightness: Brightness.dark,
          ).copyWith(
            primary: AppColors.brandPrimary,
            secondary: AppColors.brandSecondaryDark,
            tertiary: AppColors.brandTertiary,
            surface: AppColors.darkSurface,
            surfaceContainerHighest: AppColors.darkSurfaceStrong,
          ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard.withValues(alpha: 0.66),
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.dialogTitleDark,
        contentTextStyle: AppTextStyles.dialogContentLight.copyWith(
          color: AppColors.white.withValues(alpha: 0.82),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSnackBackground,
        contentTextStyle: AppTextStyles.snackBarContent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: AppSpacing.buttonPadding,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: AppSpacing.buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.2)),
          padding: AppSpacing.buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          padding: AppSpacing.textButtonPadding,
        ),
      ),
    );
  }
}
