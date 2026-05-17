import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.createdAt,
    this.paymentMethod,
    this.onTap,
    this.onLongPress,
  });

  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime? createdAt;
  final String? paymentMethod;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

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
    final color =
        AppColors.categoryColors[category] ?? AppColors.textSecondary;
    final icon = _categoryIcons[category] ?? Icons.grid_view;
    final title = (note != null && note!.isNotEmpty)
        ? note!
        : category[0].toUpperCase() + category.substring(1);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.pageMargin,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (paymentMethod != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.time(createdAt ?? date)} · $paymentMethod',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.format(amount),
              style: AppTextStyles.body.copyWith(
                fontFamily: AppTextStyles.mono.fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
