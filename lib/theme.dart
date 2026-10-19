import 'package:flutter/material.dart';

abstract final class AppColors {
  static const abyss = Color(0xFF07131F);
  static const deep = Color(0xFF0C1C2E);
  static const card = Color(0xFF13283F);
  static const line = Color(0xFF2A5274);
  static const ice = Color(0xFFE7F4FF);
  static const ink = Color(0xFFC5D9EA);
  static const muted = Color(0xFF8AADC2);
  static const azure = Color(0xFF3AD7FF);
  static const azureDeep = Color(0xFF8EEBFF);
  static const azureSoft = Color(0xFF14384C);
  static const green = Color(0xFF6DFFC8);
  static const greenSoft = Color(0xFF12382E);
  static const sand = Color(0xFF1A2744);
  static const sandInk = Color(0xFFC4D2FF);
  static const lilac = Color(0xFFC9D4FF);
  static const lilacSoft = Color(0xFF243056);

  /// Primary text on the blue panels.
  static const navy = ice;
  static const mist = abyss;
}

ThemeData buildAppTheme() {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.line),
  );

  final scheme = ColorScheme.dark(
    primary: AppColors.azure,
    onPrimary: AppColors.abyss,
    secondary: AppColors.azureDeep,
    surface: AppColors.card,
    onSurface: AppColors.ice,
    error: const Color(0xFFFF8D8D),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: AppColors.abyss,
    colorScheme: scheme,
    dividerColor: AppColors.line,
    iconTheme: const IconThemeData(color: AppColors.muted),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.deep,
      contentTextStyle: TextStyle(color: AppColors.ice),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.card),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF0C2033),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: AppColors.muted),
      hintStyle: TextStyle(color: AppColors.muted),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.azure, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.azure,
        foregroundColor: AppColors.abyss,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ice,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.azure,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.deep,
      indicatorColor: AppColors.azureSoft,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: AppColors.ice,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
