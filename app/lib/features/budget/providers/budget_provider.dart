import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';

class BudgetNotifier extends AsyncNotifier<Budget?> {
  @override
  Future<Budget?> build() =>
      ref.read(budgetRepositoryProvider).fetchCurrentMonthBudget();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).fetchCurrentMonthBudget(),
    );
  }

  Future<void> upsertBudget(double monthlyLimit) async {
    final budget =
        await ref.read(budgetRepositoryProvider).upsertBudget(monthlyLimit);
    state = AsyncData(budget);
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider<BudgetNotifier, Budget?>(BudgetNotifier.new);
