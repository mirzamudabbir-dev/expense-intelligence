import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.bgSurface,
      error: AppColors.error,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    dividerColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: AppColors.bgElevated,
  );
}
