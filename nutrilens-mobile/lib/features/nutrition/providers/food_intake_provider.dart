import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_intake_model.dart';
import '../models/weekly_report_model.dart';
import '../models/monthly_report_model.dart';
import '../services/food_intake_service.dart';

final foodIntakeServiceProvider = Provider<FoodIntakeService>((ref) => FoodIntakeService());

// Today's intake list
final foodIntakeProvider = StateNotifierProvider<FoodIntakeNotifier, AsyncValue<List<FoodIntake>>>((ref) {
  return FoodIntakeNotifier(ref.read(foodIntakeServiceProvider));
});

class FoodIntakeNotifier extends StateNotifier<AsyncValue<List<FoodIntake>>> {
  final FoodIntakeService _service;

  FoodIntakeNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> fetchToday({String? date}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getIntakes(date: date));
  }

  Future<void> logIntake(Map<String, dynamic> data) async {
    final newIntake = await _service.logIntake(data);
    state.whenData((list) {
      state = AsyncValue.data([newIntake, ...list]);
    });
  }

  Future<void> updateIntake(int id, Map<String, dynamic> data) async {
    final updated = await _service.updateIntake(id, data);
    state.whenData((list) {
      state = AsyncValue.data(list.map((e) => e.id == id ? updated : e).toList());
    });
  }

  Future<void> deleteIntake(int id) async {
    await _service.deleteIntake(id);
    state.whenData((list) {
      state = AsyncValue.data(list.where((e) => e.id != id).toList());
    });
  }

  void reset() => state = const AsyncValue.data([]);
}

// Daily summary
final dailySummaryProvider = StateNotifierProvider<DailySummaryNotifier, AsyncValue<DailySummary?>>((ref) {
  return DailySummaryNotifier(ref.read(foodIntakeServiceProvider));
});

class DailySummaryNotifier extends StateNotifier<AsyncValue<DailySummary?>> {
  final FoodIntakeService _service;

  DailySummaryNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> fetch({String? date}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getSummary(date: date));
  }

  void reset() => state = const AsyncValue.data(null);
}

// Weekly report
final weeklyReportProvider = StateNotifierProvider<WeeklyReportNotifier, AsyncValue<WeeklyReport?>>((ref) {
  return WeeklyReportNotifier(ref.read(foodIntakeServiceProvider));
});

class WeeklyReportNotifier extends StateNotifier<AsyncValue<WeeklyReport?>> {
  final FoodIntakeService _service;

  WeeklyReportNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> fetch({String? week}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getWeeklyReport(week: week));
  }

  void reset() => state = const AsyncValue.data(null);
}

// Monthly report
final monthlyReportProvider = StateNotifierProvider<MonthlyReportNotifier, AsyncValue<MonthlyReport?>>((ref) {
  return MonthlyReportNotifier(ref.read(foodIntakeServiceProvider));
});

class MonthlyReportNotifier extends StateNotifier<AsyncValue<MonthlyReport?>> {
  final FoodIntakeService _service;

  MonthlyReportNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> fetch({String? month}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getMonthlyReport(month: month));
  }

  void reset() => state = const AsyncValue.data(null);
}
