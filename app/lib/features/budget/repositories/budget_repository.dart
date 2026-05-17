import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../models/budget.dart';

class BudgetRepository {
  const BudgetRepository();

  Future<Budget?> fetchCurrentMonthBudget() async {
    final now = DateTime.now();
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', now.month)
        .eq('year', now.year)
        .maybeSingle();
    return data == null ? null : Budget.fromJson(data);
  }
}

final budgetRepositoryProvider =
    Provider<BudgetRepository>((_) => const BudgetRepository());
