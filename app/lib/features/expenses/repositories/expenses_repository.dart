import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../models/expense.dart';

class ExpensesRepository {
  const ExpensesRepository();

  Future<void> addExpense(Expense expense) async {
    await supabase.from('expenses').insert(expense.toJson());
  }

  Future<void> updateExpense(Expense expense) async {
    await supabase.from('expenses').update(expense.toJson()).eq('id', expense.id);
  }

  Future<void> deleteExpense(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }
}

final expensesRepositoryProvider =
    Provider<ExpensesRepository>((ref) => const ExpensesRepository());
