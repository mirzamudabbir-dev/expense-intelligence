import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import '../widgets/add_expense_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final Map<String, Expense> _pendingDeletes = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    var result =
        expenses.where((e) => !_pendingDeletes.containsKey(e.id)).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              (e.note?.toLowerCase().contains(q) ?? false) ||
              e.category.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedFilter == 'this_month') {
      final now = DateTime.now();
      result = result
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();
    } else if (_selectedFilter != 'all') {
      result = result.where((e) => e.category == _selectedFilter).toList();
    }

    return result;
  }

  Map<DateTime, List<Expense>> _groupByDate(List<Expense> expenses) {
    final groups = <DateTime, List<Expense>>{};
    for (final e in expenses) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      groups.putIfAbsent(key, () => []).add(e);
    }
    for (final list in groups.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return groups;
  }

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('EEE, dd MMM').format(date);
  }

  void _deleteExpense(Expense expense) {
    setState(() => _pendingDeletes[expense.id] = expense);

    final messenger = ScaffoldMessenger.of(context);
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.bgElevated,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () {
            if (mounted) setState(() => _pendingDeletes.remove(expense.id));
          },
        ),
      ),
    );

    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action &&
          mounted &&
          _pendingDeletes.containsKey(expense.id)) {
        ref.read(expensesNotifierProvider.notifier).deleteExpense(expense.id);
        setState(() => _pendingDeletes.remove(expense.id));
      }
    });
  }

  void _editExpense(Expense expense) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddExpenseSheet(initialExpense: expense),
    );
  }

  void _showOptionsSheet(Expense expense) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                title: Text('Edit', style: AppTextStyles.body),
                onTap: () {
                  Navigator.pop(ctx);
                  _editExpense(expense);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                title: Text(
                  'Delete',
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteExpense(expense);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesNotifierProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: expensesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Something went wrong', style: AppTextStyles.body),
                ),
                data: _buildList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.pageMargin),
          child: Row(
            children: [
              Semantics(
                label: 'Back',
                button: true,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Text('Transactions', style: AppTextStyles.heading2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.pageMargin),
          child: AppInput(
            controller: _searchController,
            hint: 'Search transactions',
            prefixIcon: const Icon(
              Icons.search,
              size: 16,
              color: AppColors.textTertiary,
            ),
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
        ),
        const SizedBox(height: 12),
        _buildFilterChips(),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.pageMargin,
        vertical: 4,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            value: 'all',
            selected: _selectedFilter == 'all',
            onTap: (v) => setState(() => _selectedFilter = v),
          ),
          const SizedBox(width: 8),
          ...AppConstants.categories.map((cat) {
            final label = cat[0].toUpperCase() + cat.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: label,
                value: cat,
                selected: _selectedFilter == cat,
                onTap: (v) => setState(() => _selectedFilter = v),
              ),
            );
          }),
          _FilterChip(
            label: 'This month',
            value: 'this_month',
            selected: _selectedFilter == 'this_month',
            onTap: (v) => setState(() => _selectedFilter = v),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Expense> expenses) {
    final filtered = _applyFilters(expenses);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              expenses.isEmpty
                  ? 'No transactions yet'
                  : 'No results for this filter',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByDate(filtered);
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final items = <_ListItem>[];
    for (final date in sortedDates) {
      items.add(_DateHeaderItem(date));
      for (final expense in grouped[date]!) {
        items.add(_ExpenseItem(expense));
      }
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 32,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is _DateHeaderItem) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pageMargin,
              12,
              AppConstants.pageMargin,
              4,
            ),
            child: Text(
              _dateHeader(item.date),
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        final expense = (item as _ExpenseItem).expense;
        return Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: AppColors.error,
            padding: const EdgeInsets.only(right: AppConstants.pageMargin),
            child: Text(
              'Delete',
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ),
          onDismissed: (_) => _deleteExpense(expense),
          child: TransactionTile(
            amount: expense.amount,
            category: expense.category,
            note: expense.note,
            date: expense.date,
            createdAt: expense.createdAt,
            paymentMethod: expense.paymentMethod,
            onLongPress: () => _showOptionsSheet(expense),
          ),
        )
            .animate()
            .fadeIn(
              duration: 250.ms,
              delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
            )
            .slideY(
              begin: 0.05,
              duration: 250.ms,
              delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
            );
      },
    );
  }
}

abstract class _ListItem {}

class _DateHeaderItem extends _ListItem {
  _DateHeaderItem(this.date);
  final DateTime date;
}

class _ExpenseItem extends _ListItem {
  _ExpenseItem(this.expense);
  final Expense expense;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentMuted : AppColors.bgElevated,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
