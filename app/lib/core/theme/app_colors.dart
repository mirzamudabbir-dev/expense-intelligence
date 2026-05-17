import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bgPrimary = Color(0xFF0D0D0F);
  static const bgSurface = Color(0xFF161618);
  static const bgElevated = Color(0xFF1E1E22);
  static const border = Color(0xFF2A2A2E);

  static const accent = Color(0xFF00C896);
  static const accentMuted = Color(0x2000C896);
  static const accentDim = Color(0xFF00A87A);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF48484A);

  static const error = Color(0xFFFF453A);
  static const warning = Color(0xFFFF9F0A);
  static const success = Color(0xFF30D158);

  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFF6B6B),
    'transport': Color(0xFF4ECDC4),
    'shopping': Color(0xFFFFE66D),
    'bills': Color(0xFFA8E6CF),
    'entertainment': Color(0xFFC77DFF),
    'health': Color(0xFFFF8B94),
    'education': Color(0xFF74B9FF),
    'travel': Color(0xFFFFEAA7),
    'others': Color(0xFF636E72),
  };
}
