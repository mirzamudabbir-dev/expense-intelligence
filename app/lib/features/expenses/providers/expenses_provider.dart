import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';

final expensesProvider =
    StateProvider<AsyncValue<List<Expense>>>((ref) => const AsyncValue.data([]));
