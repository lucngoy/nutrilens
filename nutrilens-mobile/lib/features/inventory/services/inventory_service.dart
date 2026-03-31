import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/inventory_model.dart';
import '../../scanner/models/product_model.dart';

class InventoryService {
  final _dio = ApiClient.instance;

  Future<List<InventoryItem>> getInventory({String? type}) async {
    try {
      final response = await _dio.get(
        '/inventory/',
        queryParameters: type != null ? {'type': type} : null,
      );
      return (response.data as List)
          .map((item) => InventoryItem.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InventoryItem> addProduct(
    ProductModel product, {
    int quantity = 1,
    String unit = 'pieces',
    String category = '',
    String storageLocation = '',
    DateTime? expirationDate,
    String notes = '',
    String inventoryType = 'personal',
    double? consumptionPerUse,
    double? usesPerWeek,
  }) async {
    try {
      final response = await _dio.post('/inventory/add/', data: {
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand ?? '',
        'image_url': product.imageUrl ?? '',
        'nutriscore': product.nutriscore ?? '',
        'calories': product.nutrition.calories,
        'fat': product.nutrition.fat,
        'saturated_fat': product.nutrition.saturatedFat,
        'carbohydrates': product.nutrition.carbohydrates,
        'sugar': product.nutrition.sugar,
        'fiber': product.nutrition.fiber,
        'protein': product.nutrition.protein,
        'salt': product.nutrition.salt,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'storage_location': storageLocation,
        'expiration_date': expirationDate?.toIso8601String().split('T')[0],
        'notes': notes,
        'inventory_type': inventoryType,
        'consumption_per_use': consumptionPerUse,
        'uses_per_week': usesPerWeek,
      });
      return InventoryItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InventoryItem> updateQuantity(int id, int quantity) async {
    try {
      final response = await _dio.patch(
        '/inventory/$id/update/',
        data: {'quantity': quantity},
      );
      return InventoryItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete('/inventory/$id/delete/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response!.data.toString();
    }
    return 'Unable to connect. Please check your connection.';
  }
}