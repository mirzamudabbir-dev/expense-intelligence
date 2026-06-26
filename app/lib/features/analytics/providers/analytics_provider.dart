import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_data.dart';
import '../repositories/analytics_repository.dart';

enum AnalyticsPeriod { week, month, year }

final selectedPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.month);

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((ref) => const AnalyticsRepository());

class AnalyticsNotifier extends AsyncNotifier<AnalyticsData> {
  @override
  Future<AnalyticsData> build() async {
    final period = ref.watch(selectedPeriodProvider);
    final now = DateTime.now();
    return ref
        .read(analyticsRepositoryProvider)
        .getMonthlyAnalytics(now.month, now.year, period.name);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final period = ref.read(selectedPeriodProvider);
      final now = DateTime.now();
      return ref
          .read(analyticsRepositoryProvider)
          .getMonthlyAnalytics(now.month, now.year, period.name);
    });
  }
}

final analyticsNotifierProvider =
    AsyncNotifierProvider<AnalyticsNotifier, AnalyticsData>(
  AnalyticsNotifier.new,
);
