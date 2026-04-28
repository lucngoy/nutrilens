import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _dio = ApiClient.instance;

  Future<MonthlyBudget?> getBudget({String? month}) async {
    try {
      final response = await _dio.get(
        '/budget/',
        queryParameters: month != null ? {'month': month} : null,
      );
      if (response.statusCode == 204) return null;
      return MonthlyBudget.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      throw _handleError(e);
    }
  }

  Future<MonthlyBudget> setBudget(double amount, {String? month}) async {
    try {
      final Map<String, dynamic> data = {'amount': amount};
      if (month != null) data['month'] = month;
      final response = await _dio.post('/budget/', data: data);
      return MonthlyBudget.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MonthlyBudget> addSpending({
    required String description,
    required double amount,
    String category = 'groceries',
    DateTime? date,
    String? month,
  }) async {
    try {
      final response = await _dio.post('/budget/spending/add/', data: {
        'description': description,
        'amount': amount,
        'category': category,
        'date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
        if (month != null) 'month': month,
      });
      return MonthlyBudget.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MonthlyBudget> deleteSpending(int entryId) async {
    try {
      final response = await _dio.delete('/budget/spending/$entryId/delete/');
      return MonthlyBudget.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) return e.response!.data.toString();
    return 'Unable to connect. Please check your connection.';
  }
}
