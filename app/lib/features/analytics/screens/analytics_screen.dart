import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/analytics_data.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined, color: AppColors.textTertiary, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load analytics.\nTap to retry.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _AnalyticsBody(data: data),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final isEmpty = data.total == 0 && data.categoryBreakdown.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(selected: period),
          const SizedBox(height: 20),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses this period.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _HeroCard(data: data, period: period),
            const SizedBox(height: 24),
            _MonthlyChart(months: data.monthlyComparison, data: data),
            const SizedBox(height: 24),
            _CategoryBreakdown(breakdown: data.categoryBreakdown, total: data.total),
            const SizedBox(height: 24),
            _TrendChart(trend: data.dailyTrend, period: period),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.04, duration: 500.ms, curve: Curves.easeOutQuart);
  }
}

// ─── Header + Segmented Control ──────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.selected});

  final AnalyticsPeriod selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text('Analytics', style: AppTextStyles.heading1),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: AnalyticsPeriod.values.map((p) {
              final isSelected = p == selected;
              final label = switch (p) {
                AnalyticsPeriod.week => 'W',
                AnalyticsPeriod.month => 'M',
                AnalyticsPeriod.year => 'Y',
              };
              return GestureDetector(
                onTap: () => ref.read(selectedPeriodProvider.notifier).state = p,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.period});

  final AnalyticsData data;
  final AnalyticsPeriod period;

  String _formatAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  double? get _momChange {
    final now = DateTime.now();
    final lastMonthDt = DateTime(now.year, now.month - 1);
    final last = data.monthlyComparison.where(
      (m) => m.month == lastMonthDt.month && m.year == lastMonthDt.year,
    ).firstOrNull;
    if (last == null || last.total == 0) return null;
    return (data.total - last.total) / last.total * 100;
  }

  String get _periodLabel {
    final now = DateTime.now();
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return switch (period) {
      AnalyticsPeriod.week => 'This Week',
      AnalyticsPeriod.month => '${months[now.month]} ${now.year}',
      AnalyticsPeriod.year => '${now.year}',
    };
  }

  String? get _pace {
    if (period != AnalyticsPeriod.month) return null;
    final now = DateTime.now();
    if (now.day == 0) return null;
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final projected = (data.total / now.day) * daysInMonth;
    return 'On pace for ${_formatAmount(projected)} this month';
  }

  @override
  Widget build(BuildContext context) {
    final mom = _momChange;
    final pace = _pace;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final dailyAvg = period == AnalyticsPeriod.month && now.day > 0
        ? data.total / now.day
        : data.total / 30;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _periodLabel,
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (mom != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: mom >= 0
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mom >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: mom >= 0 ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${mom.abs().toStringAsFixed(0)}% vs last month',
                        style: AppTextStyles.caption.copyWith(
                          color: mom >= 0 ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(data.total),
            style: AppTextStyles.mono.copyWith(fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'total spent',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                icon: Icons.trending_up_outlined,
                label: 'Daily avg',
                value: _formatAmount(dailyAvg),
              ),
              if (period == AnalyticsPeriod.month) ...[
                const SizedBox(width: 16),
                _StatPill(
                  icon: Icons.calendar_today_outlined,
                  label: 'Days left',
                  value: '${daysInMonth - now.day}',
                ),
              ],
              if (data.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(width: 16),
                _StatPill(
                  icon: Icons.circle,
                  iconColor: AppColors.categoryColors[data.categoryBreakdown.first.categoryId],
                  label: 'Top',
                  value: _capitalize(data.categoryBreakdown.first.categoryId),
                ),
              ],
            ],
          ),
          if (pace != null) ...[
            const SizedBox(height: 12),
            Text(
              pace,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor ?? AppColors.textTertiary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            Text(
              value,
              style: AppTextStyles.mono.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months, required this.data});

  final List<MonthlyTotal> months;
  final AnalyticsData data;

  static const _monthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final safeMonths = months.isEmpty
        ? List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return MonthlyTotal(month: d.month, year: d.year, total: 0);
          })
        : months;

    double maxVal = safeMonths.map((m) => m.total).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1.0;

    // MoM change for subtitle
    double? momPct;
    if (safeMonths.length >= 2) {
      final cur = safeMonths.last.total;
      final prev = safeMonths[safeMonths.length - 2].total;
      if (prev > 0) momPct = (cur - prev) / prev * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Last 6 Months', style: AppTextStyles.heading2),
            const Spacer(),
            if (momPct != null)
              Text(
                '${momPct >= 0 ? '↑' : '↓'} ${momPct.abs().toStringAsFixed(0)}% MoM',
                style: AppTextStyles.caption.copyWith(
                  color: momPct >= 0 ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgElevated,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = safeMonths[groupIndex];
                      return BarTooltipItem(
                        '${_monthAbbr[m.month]}\n₹${m.total.toStringAsFixed(0)}',
                        AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= safeMonths.length) return const SizedBox.shrink();
                        final isCurrent = safeMonths[idx].month == now.month &&
                            safeMonths[idx].year == now.year;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthAbbr[safeMonths[idx].month],
                            style: AppTextStyles.caption.copyWith(
                              color: isCurrent ? AppColors.accent : AppColors.textTertiary,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: safeMonths.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  final isCurrent = m.month == now.month && m.year == now.year;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: m.total,
                        color: isCurrent
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.28),
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
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
        Text('By Category', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: visible.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final pct = total > 0 ? cat.total / total : 0.0;
              final color = AppColors.categoryColors[cat.categoryId] ?? AppColors.textSecondary;
              final name = cat.categoryId[0].toUpperCase() + cat.categoryId.substring(1);

              return Column(
                children: [
                  if (idx > 0)
                    const Divider(color: AppColors.border, height: 1, thickness: 1),
                  _CategoryRow(name: name, color: color, amount: cat.total, pct: pct),
                ],
              );
            }).toList(),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name, style: AppTextStyles.body),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: AppTextStyles.mono.copyWith(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(width: constraints.maxWidth, color: AppColors.bgElevated),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      width: constraints.maxWidth * pct,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trend Line Chart ─────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend, required this.period});

  final List<DailyTotal> trend;
  final AnalyticsPeriod period;

  static const _monthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  bool get _isYearView => period == AnalyticsPeriod.year;

  String _label(DailyTotal d) {
    if (_isYearView) {
      final month = int.tryParse(d.day.length >= 7 ? d.day.substring(5, 7) : '0') ?? 0;
      return _monthAbbr[month.clamp(0, 12)];
    }
    return d.day.length >= 5 ? d.day.substring(5) : d.day;
  }

  @override
  Widget build(BuildContext context) {
    final safeTrend = trend.isEmpty
        ? (_isYearView
            ? List.generate(12, (i) {
                final d = DateTime(DateTime.now().year, DateTime.now().month - 11 + i);
                return DailyTotal(
                  day: '${d.year}-${d.month.toString().padLeft(2, '0')}',
                  total: 0,
                );
              })
            : List.generate(7, (i) {
                final d = DateTime.now().subtract(Duration(days: 6 - i));
                return DailyTotal(
                  day: '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                  total: 0,
                );
              }))
        : trend;

    double maxVal = safeTrend.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1.0;

    final peakIdx = safeTrend.indexWhere((d) => d.total == maxVal);

    final spots = safeTrend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.total))
        .toList();

    final title = _isYearView ? 'Monthly Trend' : 'Spending Trend';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                maxY: maxVal * 1.3,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgElevated,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((s) => LineTooltipItem(
                              '₹${s.y.toStringAsFixed(0)}',
                              AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx != peakIdx || maxVal <= 1.0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '₹${maxVal.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (safeTrend.length / 5).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= safeTrend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _label(safeTrend[idx]),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
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
                    curveSmoothness: 0.35,
                    color: AppColors.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: idx == peakIdx ? 5 : 3,
                        color: AppColors.accent,
                        strokeWidth: idx == peakIdx ? 2 : 0,
                        strokeColor: AppColors.bgPrimary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.22),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
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
