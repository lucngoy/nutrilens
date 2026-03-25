import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
//   static const String baseUrl = 'http://172.20.18.123:8000/api'; // Fac IP
  static const String baseUrl = 'http://192.168.3.34:8000/api'; // Home IP
  static const _storage = FlutterSecureStorage();
  static Dio? _instance;

  static Dio get instance {
    if (_instance != null) return _instance!;

    _instance = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _instance!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final refreshToken =
                await _storage.read(key: 'refresh_token');
            if (refreshToken == null) return handler.next(error);

            // Refresh le token
            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final response = await refreshDio.post(
              '/users/token/refresh/',
              data: {'refresh': refreshToken},
            );

            final newAccess = response.data['access'];
            await _storage.write(
                key: 'access_token', value: newAccess);

            // Retry la requête originale avec le nouveau token
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccess';
            final retryResponse = await _instance!.fetch(
              error.requestOptions,
            );
            return handler.resolve(retryResponse);
          } catch (_) {
            await _storage.deleteAll();
            return handler.next(error);
          }
        }
        print("❌ ERROR: ${error.message}");
        print("❌ TYPE: ${error.type}");
        return handler.next(error);
      },
    ));

    return _instance!;
  }
}