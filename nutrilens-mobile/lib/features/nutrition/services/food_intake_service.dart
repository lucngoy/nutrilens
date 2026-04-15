import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/food_intake_model.dart';
import '../models/weekly_report_model.dart';
import '../models/monthly_report_model.dart';

class FoodIntakeService {
  final Dio _dio = ApiClient.instance;

  Future<List<FoodIntake>> getIntakes({String? date}) async {
    final params = date != null ? {'date': date} : <String, dynamic>{};
    final response = await _dio.get('/users/food-intake/', queryParameters: params);
    return (response.data as List).map((e) => FoodIntake.fromJson(e)).toList();
  }

  Future<FoodIntake> logIntake(Map<String, dynamic> data) async {
    final response = await _dio.post('/users/food-intake/', data: data);
    return FoodIntake.fromJson(response.data);
  }

  Future<FoodIntake> updateIntake(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/food-intake/$id/', data: data);
    return FoodIntake.fromJson(response.data);
  }

  Future<void> deleteIntake(int id) async {
    await _dio.delete('/users/food-intake/$id/');
  }

  Future<DailySummary> getSummary({String? date}) async {
    final params = date != null ? {'date': date} : <String, dynamic>{};
    final response = await _dio.get('/users/food-intake/summary/', queryParameters: params);
    return DailySummary.fromJson(response.data);
  }

  Future<WeeklyReport> getWeeklyReport({String? week}) async {
    final params = week != null ? {'week': week} : <String, dynamic>{};
    final response = await _dio.get('/users/food-intake/weekly/', queryParameters: params);
    return WeeklyReport.fromJson(response.data);
  }

  Future<MonthlyReport> getMonthlyReport({String? month}) async {
    final params = month != null ? {'month': month} : <String, dynamic>{};
    final response = await _dio.get('/users/food-intake/monthly/', queryParameters: params);
    return MonthlyReport.fromJson(response.data);
  }
}
