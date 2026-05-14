import 'package:dio/dio.dart' show Dio, FormData, MultipartFile;
import '../../../core/network/api_client.dart';
import '../models/user_product_model.dart';

class UserProductService {
  final _dio = ApiClient.instance;

  Future<List<UserProductModel>> getAll() async {
    final response = await _dio.get('/inventory/user-products/');
    return (response.data as List)
        .map((e) => UserProductModel.fromJson(e))
        .toList();
  }

  Future<UserProductModel> create(UserProductModel product, {String? imagePath}) async {
    final data = FormData.fromMap({
      ...product.toJson()..removeWhere((_, v) => v == null),
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    final response = await _dio.post('/inventory/user-products/', data: data);
    return UserProductModel.fromJson(response.data);
  }

  Future<UserProductModel> update(int id, UserProductModel product, {String? imagePath}) async {
    final data = FormData.fromMap({
      ...product.toJson()..removeWhere((_, v) => v == null),
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    final response = await _dio.patch('/inventory/user-products/$id/', data: data);
    return UserProductModel.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/inventory/user-products/$id/');
  }
}
