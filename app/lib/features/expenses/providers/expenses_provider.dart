import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../models/expense.dart';
import '../repositories/expenses_repository.dart';

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final userId = supabase.auth.currentUser!.id;
    final sub = supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .listen((data) {
          state = AsyncData(data.map(Expense.fromJson).toList());
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> addExpense(Expense expense) async {
    await ref.read(expensesRepositoryProvider).addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await ref.read(expensesRepositoryProvider).updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expensesRepositoryProvider).deleteExpense(id);
  }
}

final expensesNotifierProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);
