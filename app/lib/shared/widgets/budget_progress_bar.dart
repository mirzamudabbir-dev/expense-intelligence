import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key, required this.percentage});

  final double percentage;

  Color get _fillColor {
    if (percentage >= 1.0) return AppColors.error;
    if (percentage >= 0.8) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: percentage.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.bgElevated,
          valueColor: AlwaysStoppedAnimation(_fillColor),
          minHeight: 6,
        ),
      ),
    );
  }
}
