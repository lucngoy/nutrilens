import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/analysis_model.dart';

class AnalysisService {
  final _dio = ApiClient.instance;

  Future<AnalysisResult> analyzeProduct(ProductModel product) async {
    try {
      final response = await _dio.post('/users/health/analyze/', data: {
        'nutrition': {
          'calories': product.nutrition.calories,
          'sugar': product.nutrition.sugar,
          'saturated_fat': product.nutrition.saturatedFat,
          'salt': product.nutrition.salt,
          'fat': product.nutrition.fat,
          'protein': product.nutrition.protein,
          'carbohydrates': product.nutrition.carbohydrates,
        },
        'allergens': product.allergens,
        'ingredients': product.ingredients,
        'nutriscore': product.nutriscore,
      });
      return AnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? 'Analysis failed';
      throw Exception(msg);
    }
  }
}
