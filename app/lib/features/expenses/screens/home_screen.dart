import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/budget/providers/budget_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/budget_progress_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../providers/home_providers.dart';
import '../widgets/add_expense_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final todayCount = ref.watch(todayCountProvider);
    final budgetAsync = ref.watch(budgetNotifierProvider);
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final weeklyData = ref.watch(weeklyChartDataProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _Header(),
                  const SizedBox(height: 20),
                  _MonthlyBudgetCard(
                    monthlyTotal: monthlyTotal,
                    budgetAsync: budgetAsync,
                  ),
                  const SizedBox(height: 12),
                  _TodayCard(total: todayTotal, count: todayCount),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'This month'),
                  const SizedBox(height: 8),
                  if (categoryBreakdown.isNotEmpty)
                    _CategoryRow(entries: categoryBreakdown),
                  if (categoryBreakdown.isEmpty)
                    Text(
                      'No expenses this month',
                      style: AppTextStyles.caption,
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'This week'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 120,
                      child: _WeeklyBarChart(data: weeklyData),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Recent',
                    trailing: GestureDetector(
                      onTap: () => context.push('/history'),
                      child: Text(
                        'See all',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recentExpenses.isEmpty)
                    Text(
                      'No expenses yet',
                      style: AppTextStyles.caption,
                    ),
                  ...recentExpenses.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionTile(
                        amount: e.amount,
                        category: e.category,
                        note: e.note,
                        date: e.date,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _Fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  _Header();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final fullName =
        (user?.userMetadata?['full_name'] as String? ?? '').trim();
    final firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : (user?.email?.split('@').first ?? 'there');
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.bgElevated,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: AppTextStyles.label.copyWith(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_greeting, $firstName',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Semantics(
          label: 'Notifications',
          button: true,
          child: const Icon(
            Icons.notifications_outlined,
            size: 24,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Monthly Budget Card ───────────────────────────────────────────────────────

class _MonthlyBudgetCard extends StatelessWidget {
  const _MonthlyBudgetCard({
    required this.monthlyTotal,
    required this.budgetAsync,
  });

  final double monthlyTotal;
  final AsyncValue<dynamic> budgetAsync;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return budgetAsync.when(
      loading: () => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthLabel,
                style:
                    AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(monthlyTotal),
              style: AppTextStyles.display,
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (budget) {
        final hasBudget = budget != null;
        final limit = hasBudget ? budget.monthlyLimit as double : 0.0;
        final remaining = hasBudget ? (limit - monthlyTotal) : 0.0;
        final percentage = hasBudget && limit > 0 ? monthlyTotal / limit : 0.0;

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel,
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(monthlyTotal),
                style: AppTextStyles.display,
              ),
              if (hasBudget) ...[
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(remaining.clamp(0, double.infinity))} remaining of ${CurrencyFormatter.format(limit)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                BudgetProgressBar(percentage: percentage),
              ] else ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/budget'),
                  child: Text(
                    'Set a budget →',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Today Card ────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today',
                style:
                    AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(total),
                style: AppTextStyles.heading2.copyWith(
                  fontFamily: AppTextStyles.mono.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'transaction' : 'transactions'}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entries});

  final List<MapEntry<String, double>> entries;

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.indexed.map((item) {
          final (i, entry) = item;
          final color =
              AppColors.categoryColors[entry.key] ?? AppColors.textSecondary;
          final icon = _icons[entry.key] ?? Icons.grid_view;
          final name = entry.key[0].toUpperCase() + entry.key.substring(1);

          return Padding(
            padding: EdgeInsets.only(right: i < entries.length - 1 ? 8 : 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(102)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '$name ${CurrencyFormatter.compact(entry.value)}',
                    style: AppTextStyles.label.copyWith(color: color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.data});

  final Map<DateTime, double> data;

  @override
  Widget build(BuildContext context) {
    final days = data.keys.toList(); // already sorted oldest→today
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final maxAmount = data.values.fold(0.0, max);
    final maxY = max(maxAmount * 1.3, 100.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('E').format(days[i]).substring(0, 3),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgElevated,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              CurrencyFormatter.format(rod.toY),
              AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
        barGroups: days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          final isToday = day == todayNorm;
          final amount = data[day] ?? 0.0;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: isToday ? max(amount, 0) : 0,
                color: AppColors.accent,
                width: 24,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppColors.bgElevated,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x4D00C896),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (_) => const AddExpenseSheet(),
        ),
        backgroundColor: AppColors.accent,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
