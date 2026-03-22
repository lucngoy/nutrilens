import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final scannedProductProvider =
    StateNotifierProvider<ScannedProductNotifier, AsyncValue<ProductModel?>>(
  (ref) => ScannedProductNotifier(ref.read(productServiceProvider)),
);

class ScannedProductNotifier extends StateNotifier<AsyncValue<ProductModel?>> {
  final ProductService _productService;

  ScannedProductNotifier(this._productService)
      : super(const AsyncValue.data(null));

  Future<void> fetchProduct(String barcode) async {
    state = const AsyncValue.loading();
    try {
      final product = await _productService.getProductByBarcode(barcode);
      state = AsyncValue.data(product);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}