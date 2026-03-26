import 'dart:io';
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
      final response = await _dio.post('/users/login/', data: {
        'username': username,
        'password': password,
      });

      await StorageService.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
    } on DioException catch (e) {
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

  Future<UserModel> updateProfile({required Map<String, dynamic> data}) async {
    try {
      final response = await _dio.patch('/users/profile/', data: data);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      await _dio.patch('/users/profile/avatar/', data: formData);
      return await getProfile();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refresh = await StorageService.getRefreshToken();
      if (refresh == null) return false;

      final response = await _dio.post('/users/token/refresh/', data: {
        'refresh': refresh,
      });

      await StorageService.saveTokens(
        access: response.data['access'],
        refresh: refresh,
      );
      return true;
    } on DioException {
      await StorageService.clearTokens();
      return false;
    }
  }

    String _handleError(DioException e) {
        if (e.response != null) {
            final data = e.response!.data;
            if (data is Map) {
            final messages = <String>[];
            data.forEach((field, value) {
                final fieldName = _formatFieldName(field.toString());
                if (value is List) {
                for (final msg in value) {
                    messages.add('$fieldName: $msg');
                }
                } else {
                messages.add('$fieldName: $value');
                }
            });
            return messages.join('\n');
            }
        }
        return 'Something went wrong. Please check your connection.';
    }

    String _formatFieldName(String field) {
        switch (field) {
            case 'username': return 'Username';
            case 'password': return 'Password';
            case 'email': return 'Email';
            case 'non_field_errors': return 'Error';
            case 'detail': return 'Error';
            default: return field;
        }
    }
}