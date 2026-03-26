import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';
import '../../scanner/models/product_model.dart';

final inventoryServiceProvider =
    Provider<InventoryService>((ref) => InventoryService());

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>(
  (ref) => InventoryNotifier(ref.read(inventoryServiceProvider)),
);

class InventoryNotifier
    extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final InventoryService _service;

  InventoryNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> fetchInventory() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getInventory();
      state = AsyncValue.data(items);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      final item = await _service.addProduct(product);
      final current = state.valueOrNull ?? [];
      final index = current.indexWhere((i) => i.barcode == item.barcode);
      if (index >= 0) {
        final updated = [...current];
        updated[index] = item;
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data([item, ...current]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(int id, int quantity) async {
    try {
      final item = await _service.updateQuantity(id, quantity < 0 ? 0 : quantity);
      final current = state.valueOrNull ?? [];
      final updated = current.map((i) => i.id == id ? item : i).toList();
      state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _service.deleteItem(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((i) => i.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}