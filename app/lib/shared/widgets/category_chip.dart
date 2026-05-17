import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.onTap});

  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[category] ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          border: Border.all(color: color.withAlpha(102)),
        ),
        child: Text(
          category[0].toUpperCase() + category.substring(1),
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ),
    );
  }
}
