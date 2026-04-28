import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<MonthlyBudget?>>(
  (ref) => BudgetNotifier(ref.read(budgetServiceProvider)),
);

class BudgetNotifier extends StateNotifier<AsyncValue<MonthlyBudget?>> {
  final BudgetService _service;

  BudgetNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> fetch({String? month}) async {
    state = const AsyncValue.loading();
    try {
      final budget = await _service.getBudget(month: month);
      state = AsyncValue.data(budget);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> setBudget(double amount, {String? month}) async {
    try {
      final budget = await _service.setBudget(amount, month: month);
      state = AsyncValue.data(budget);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addSpending({
    required String description,
    required double amount,
    String category = 'groceries',
    DateTime? date,
    String? month,
  }) async {
    try {
      final budget = await _service.addSpending(
        description: description,
        amount: amount,
        category: category,
        date: date,
        month: month,
      );
      state = AsyncValue.data(budget);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSpending(int entryId) async {
    try {
      final budget = await _service.deleteSpending(entryId);
      state = AsyncValue.data(budget);
    } catch (e) {
      rethrow;
    }
  }
}
