import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CategorySelectorSheet extends StatelessWidget {
  const CategorySelectorSheet({super.key, required this.initialCategory});

  final String initialCategory;

  static const _icons = <String, IconData>{
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_bag,
    'bills': Icons.receipt,
    'entertainment': Icons.tv,
    'health': Icons.favorite,
    'education': Icons.menu_book,
    'travel': Icons.flight,
    'others': Icons.grid_view,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Category', style: AppTextStyles.heading2),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppConstants.categories.length,
              itemBuilder: (ctx, i) {
                final cat = AppConstants.categories[i];
                final selected = cat == initialCategory;
                final color =
                    AppColors.categoryColors[cat] ?? AppColors.textSecondary;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentMuted : Colors.transparent,
                      border: Border.all(
                        color: selected ? AppColors.accent : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icons[cat] ?? Icons.grid_view,
                            color: color, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          cat[0].toUpperCase() + cat.substring(1),
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
