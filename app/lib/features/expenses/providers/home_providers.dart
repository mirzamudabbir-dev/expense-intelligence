import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import 'expenses_provider.dart';

final monthlyTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final todayTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final todayCountProvider = Provider<int>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day)
      .length;
});

// Returns last 7 days (6 days ago → today), oldest first, missing days = 0.0
final weeklyChartDataProvider = Provider<Map<DateTime, double>>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);

  final result = <DateTime, double>{};
  for (var i = 6; i >= 0; i--) {
    result[todayNorm.subtract(Duration(days: i))] = 0.0;
  }
  for (final e in expenses) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    if (result.containsKey(day)) {
      result[day] = result[day]! + e.amount;
    }
  }
  return result;
});

// Current month, sorted by spend descending
final categoryBreakdownProvider =
    Provider<List<MapEntry<String, double>>>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final breakdown = <String, double>{};
  for (final e in expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)) {
    breakdown[e.category] = (breakdown[e.category] ?? 0.0) + e.amount;
  }
  return breakdown.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
});

final recentExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesNotifierProvider).valueOrNull ?? [];
  return expenses.take(5).toList();
});
