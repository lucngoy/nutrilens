import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/scan_history_model.dart';
import '../models/product_model.dart';

class ScanHistoryService {
  final _dio = ApiClient.instance;

  Future<List<ScanHistoryItem>> getRecentScans({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/inventory/scans/',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((item) => ScanHistoryItem.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw e.message ?? 'Error fetching scan history';
    }
  }

  Future<void> addScan(ProductModel product) async {
    try {
      await _dio.post('/inventory/scans/add/', data: {
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand ?? '',
        'image_url': product.imageUrl ?? '',
        'nutriscore': product.nutriscore ?? '',
        'calories': product.nutrition.calories,
      });
    } on DioException {
      // Silencieux — un échec de tracking ne doit pas bloquer l'user
    }
  }
}