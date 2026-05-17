import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/supabase_service.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import 'category_selector_sheet.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, this.initialExpense});

  final Expense? initialExpense;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteController = TextEditingController();

  String _category = 'others';
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isSaving = false;

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
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    if (e != null) {
      _amountController.text =
          e.amount % 1 == 0 ? e.amount.toInt().toString() : e.amount.toString();
      _noteController.text = e.note ?? '';
      _category = e.category;
      _date = e.date;
      _paymentMethod = e.paymentMethod;
    }
    _amountController.addListener(_onAmountChanged);
    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _amountFocus.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  bool get _isAmountValid {
    final v = double.tryParse(_amountController.text.trim()) ?? 0;
    return v > 0;
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day) {
      return 'Today';
    }
    return DateFormat('EEE, dd MMM').format(_date);
  }

  Future<void> _openCategorySelector() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CategorySelectorSheet(initialCategory: _category),
    );
    if (result != null && mounted) setState(() => _category = result);
  }

  Future<void> _pickDate() async {
    if (Platform.isIOS) {
      DateTime temp = _date;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 300,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ),
        ),
      );
      if (mounted) setState(() => _date = temp);
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.accent),
          ),
          child: child!,
        ),
      );
      if (picked != null && mounted) setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;
    setState(() => _isSaving = true);
    final trimmedNote =
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    try {
      if (widget.initialExpense != null) {
        final updated = widget.initialExpense!.copyWith(
          amount: amount,
          category: _category,
          note: trimmedNote,
          date: _date,
          paymentMethod: _paymentMethod,
        );
        await ref.read(expensesNotifierProvider.notifier).updateExpense(updated);
      } else {
        final expense = Expense(
          id: '',
          userId: supabase.auth.currentUser!.id,
          amount: amount,
          category: _category,
          note: trimmedNote,
          date: _date,
          paymentMethod: _paymentMethod,
          createdAt: DateTime.now(),
        );
        await ref.read(expensesNotifierProvider.notifier).addExpense(expense);
      }
      if (mounted) Navigator.pop(context);
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDivider() => Container(height: 1, color: AppColors.border);

  Widget _buildRowTile({
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: AppColors.bgElevated,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(child: leading),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String method, String label) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentMuted : AppColors.bgElevated,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '₹',
          style: AppTextStyles.mono.copyWith(
            fontSize: 40,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.mono.copyWith(
              fontSize: 40,
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTextStyles.mono.copyWith(
                fontSize: 40,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldGroup() {
    final catColor =
        AppColors.categoryColors[_category] ?? AppColors.textSecondary;
    final catIcon = _categoryIcons[_category] ?? Icons.grid_view;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Category
          _buildRowTile(
            leading: Row(
              children: [
                Icon(catIcon, color: catColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  _category[0].toUpperCase() + _category.substring(1),
                  style: AppTextStyles.body,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
            onTap: _openCategorySelector,
          ),
          _buildDivider(),
          // Note
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _noteController,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: 'What was this for?',
                hintStyle: AppTextStyles.body
                    .copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _buildDivider(),
          // Date
          _buildRowTile(
            leading: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(_dateLabel, style: AppTextStyles.body),
              ],
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
            onTap: _pickDate,
          ),
          _buildDivider(),
          // Payment method
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Paid with',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                _buildPaymentChip('cash', 'Cash'),
                const SizedBox(width: 8),
                _buildPaymentChip('upi', 'UPI'),
                const SizedBox(width: 8),
                _buildPaymentChip('card', 'Card'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.pageMargin),
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
                Text(
                  widget.initialExpense != null ? 'Edit Expense' : 'Add Expense',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildAmountField(),
                const SizedBox(height: 24),
                _buildFieldGroup(),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _isAmountValid ? 1.0 : 0.4,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isAmountValid && !_isSaving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusXl),
                        ),
                      ),
                      child: Text(
                        widget.initialExpense != null
                            ? 'Update Expense'
                            : 'Save Expense',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
