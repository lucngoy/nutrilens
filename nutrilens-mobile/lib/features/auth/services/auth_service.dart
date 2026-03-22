import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final _dio = ApiClient.instance;

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/users/register/', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      print('Attempting login for: $username');
      final response = await _dio.post('/users/login/', data: {
        'username': username,
        'password': password,
      });
      print('Login response: ${response.data}');
      await StorageService.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
    } on DioException catch (e) {
      print('Login error: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/users/profile/');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await StorageService.clearTokens();
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data.values.first is List
            ? data.values.first.first.toString()
            : data.values.first.toString();
      }
    }
    return 'Une erreur est survenue. Vérifie ta connexion.';
  }
}