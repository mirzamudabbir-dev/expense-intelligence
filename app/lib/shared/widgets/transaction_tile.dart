import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import 'amount_display.dart';
import 'category_chip.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.onTap,
  });

  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final VoidCallback? onTap;

  static const _categoryIcons = <String, IconData>{
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
    final color = AppColors.categoryColors[category] ?? AppColors.textSecondary;
    final icon = _categoryIcons[category] ?? Icons.grid_view;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryChip(category: category),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountDisplay(amount: amount),
                const SizedBox(height: 4),
                Text(DateFormatter.short(date), style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
