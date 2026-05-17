import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.amount, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyFormatter.format(amount),
      style: style ?? AppTextStyles.mono,
    );
  }
}
