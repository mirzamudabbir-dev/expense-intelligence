import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../models/analytics_data.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final analyticsAsync = ref.watch(analyticsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: analyticsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (_, __) => Center(
            child: GestureDetector(
              onTap: () => ref.read(analyticsNotifierProvider.notifier).refresh(),
              child: Text(
                'Could not load data. Tap to retry.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (data) => _AnalyticsBody(data: data, topPadding: top),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.data, required this.topPadding});

  final AnalyticsData data;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final isEmpty = data.total == 0 && data.categoryBreakdown.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Analytics', style: AppTextStyles.heading1),
          const SizedBox(height: 16),
          _PeriodSelector(selected: period),
          const SizedBox(height: 24),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses this period.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _SummaryRow(data: data),
            const SizedBox(height: 24),
            _MonthlyChart(months: data.monthlyComparison),
            const SizedBox(height: 24),
            _CategoryBreakdown(breakdown: data.categoryBreakdown, total: data.total),
            const SizedBox(height: 24),
            _DailyTrend(trend: data.dailyTrend),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.selected});

  final AnalyticsPeriod selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: AnalyticsPeriod.values.map((p) {
        final isSelected = p == selected;
        final label = switch (p) {
          AnalyticsPeriod.week => 'Week',
          AnalyticsPeriod.month => 'Month',
          AnalyticsPeriod.year => 'Year',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => ref.read(selectedPeriodProvider.notifier).state = p,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentMuted : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary Row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data});

  final AnalyticsData data;

  String _formatAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final dailyAvg = data.total / daysInMonth;
    final topCat = data.categoryBreakdown.isNotEmpty
        ? data.categoryBreakdown.first.categoryId
        : '—';
    final topCatColor = AppColors.categoryColors[topCat] ?? AppColors.textSecondary;

    return Row(
      children: [
        Expanded(child: _SummaryCard(value: _formatAmount(data.total), label: 'Total Spent')),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(value: _formatAmount(dailyAvg), label: 'Daily Avg')),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            value: topCat == '—'
                ? '—'
                : topCat[0].toUpperCase() + topCat.substring(1),
            label: 'Top Category',
            valueColor: topCat == '—' ? null : topCatColor,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.mono.copyWith(
              fontSize: 15,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months});

  final List<MonthlyTotal> months;

  static const _monthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxVal = months.isEmpty
        ? 1.0
        : months.map((m) => m.total).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Last 6 Months'),
        const SizedBox(height: 8),
        AppCard(
          child: SizedBox(
            height: 180,
            child: months.isEmpty
                ? Center(
                    child: Text('No data', style: AppTextStyles.caption),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxVal * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.bgElevated,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final m = months[groupIndex];
                            return BarTooltipItem(
                              '₹${m.total.toStringAsFixed(0)}',
                              AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _monthAbbr[months[idx].month],
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: months.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final m = entry.value;
                        final isCurrent =
                            m.month == now.month && m.year == now.year;
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: m.total,
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.bgElevated,
                              width: 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOutQuart,
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.breakdown, required this.total});

  final List<CategoryTotal> breakdown;
  final double total;

  @override
  Widget build(BuildContext context) {
    final visible = breakdown.where((c) => c.total > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'By Category'),
        const SizedBox(height: 8),
        ...visible.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.total / total : 0.0;
          final color =
              AppColors.categoryColors[cat.categoryId] ?? AppColors.textSecondary;
          final name = cat.categoryId[0].toUpperCase() +
              cat.categoryId.substring(1);

          return Padding(
            padding: EdgeInsets.only(bottom: idx < visible.length - 1 ? 8 : 0),
            child: _CategoryRow(
              name: name,
              color: color,
              amount: cat.total,
              pct: pct,
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.color,
    required this.amount,
    required this.pct,
  });

  final String name;
  final Color color;
  final double amount;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: AppTextStyles.body),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: AppTextStyles.mono.copyWith(fontSize: 15),
              ),
              Text(
                ' · ${(pct * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    color: AppColors.bgElevated,
                  ),
                  Container(
                    width: constraints.maxWidth * pct,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Daily Trend Line Chart ───────────────────────────────────────────────────

class _DailyTrend extends StatelessWidget {
  const _DailyTrend({required this.trend});

  final List<DailyTotal> trend;

  @override
  Widget build(BuildContext context) {
    final maxVal = trend.isEmpty
        ? 1.0
        : trend.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    final spots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.total))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Daily Trend'),
        const SizedBox(height: 8),
        AppCard(
          child: SizedBox(
            height: 160,
            child: trend.isEmpty
                ? Center(child: Text('No data', style: AppTextStyles.caption))
                : LineChart(
                    LineChartData(
                      maxY: maxVal * 1.2,
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.bgElevated,
                          getTooltipItems: (spots) => spots
                              .map((s) => LineTooltipItem(
                                    '₹${s.y.toStringAsFixed(0)}',
                                    AppTextStyles.caption.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (trend.length / 5).ceilToDouble().clamp(1, double.infinity),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= trend.length) {
                                return const SizedBox.shrink();
                              }
                              final label = trend[idx].day.length >= 5
                                  ? trend[idx].day.substring(5)
                                  : trend[idx].day;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.accent,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.accent,
                              strokeWidth: 0,
                              strokeColor: Colors.transparent,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accent.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart,
                  ),
          ),
        ),
      ],
    );
  }
}
