import 'package:dio/dio.dart';
import '../storage/storage_service.dart';

class ApiClient {
  // static const String baseUrl = 'http://172.20.18.123:8000/api'; // Fac IP
  static const String baseUrl = 'http://192.168.3.34:8000/api'; // Home IP
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
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isRetry = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !isRetry) {
          try {
            final refreshToken = await StorageService.getRefreshToken();
            if (refreshToken == null) {
              await StorageService.clearTokens();
              return handler.next(error);
            }

            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final response = await refreshDio.post(
              '/users/token/refresh/',
              data: {'refresh': refreshToken},
            );

            final newAccess = response.data['access'];
            await StorageService.saveTokens(
              access: newAccess,
              refresh: refreshToken,
            );

            // Retry avec flag anti-boucle
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccess';
            retryOptions.extra['retried'] = true;
            
            final retryResponse = await _instance!.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            await StorageService.clearTokens();
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    return _instance!;
  }
}