import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ProductService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://world.openfoodfacts.org',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/api/v0/product/$barcode.json');
      final data = response.data;

      if (data['status'] != 1) return null;

      return ProductModel.fromOpenFoodFacts(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    }
    return 'Unable to fetch product data. Please try again.';
  }
}