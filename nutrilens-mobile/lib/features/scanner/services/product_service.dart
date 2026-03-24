import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductService {
  final _dio = ApiClient.instance;

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/inventory/product/$barcode/');
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