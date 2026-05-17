class CategoryTotal {
  const CategoryTotal({required this.categoryId, required this.total});

  final String categoryId;
  final double total;

  factory CategoryTotal.fromJson(Map<String, dynamic> j) => CategoryTotal(
        categoryId: j['category_id'] as String,
        total: (j['total'] as num).toDouble(),
      );
}

class DailyTotal {
  const DailyTotal({required this.day, required this.total});

  final String day;
  final double total;

  factory DailyTotal.fromJson(Map<String, dynamic> j) => DailyTotal(
        day: j['day'] as String,
        total: (j['total'] as num).toDouble(),
      );
}

class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.year, required this.total});

  final int month;
  final int year;
  final double total;

  factory MonthlyTotal.fromJson(Map<String, dynamic> j) => MonthlyTotal(
        month: j['month'] as int,
        year: j['year'] as int,
        total: (j['total'] as num).toDouble(),
      );
}

class AnalyticsData {
  const AnalyticsData({
    required this.total,
    required this.categoryBreakdown,
    required this.dailyTrend,
    required this.monthlyComparison,
  });

  final double total;
  final List<CategoryTotal> categoryBreakdown;
  final List<DailyTotal> dailyTrend;
  final List<MonthlyTotal> monthlyComparison;

  factory AnalyticsData.fromJson(Map<String, dynamic> j) => AnalyticsData(
        total: (j['total'] as num).toDouble(),
        categoryBreakdown: (j['category_breakdown'] as List)
            .map((e) => CategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyTrend: (j['daily_trend'] as List)
            .map((e) => DailyTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        monthlyComparison: (j['monthly_comparison'] as List)
            .map((e) => MonthlyTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static AnalyticsData empty() => const AnalyticsData(
        total: 0,
        categoryBreakdown: [],
        dailyTrend: [],
        monthlyComparison: [],
      );
}
