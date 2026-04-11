import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_history_model.dart';
import '../services/scan_history_service.dart';

final scanHistoryServiceProvider =
    Provider<ScanHistoryService>((ref) => ScanHistoryService());

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, AsyncValue<List<ScanHistoryItem>>>(
  (ref) => ScanHistoryNotifier(ref.read(scanHistoryServiceProvider)),
);

class ScanHistoryNotifier
    extends StateNotifier<AsyncValue<List<ScanHistoryItem>>> {
  final ScanHistoryService _service;

  ScanHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchRecentScans();
  }

  Future<void> fetchRecentScans({int limit = 10}) async {
    // Don't flash a spinner if we already have data — just silently refresh
    if (state is! AsyncData) {
      state = const AsyncValue.loading();
    }
    try {
      final scans = await _service.getRecentScans(limit: limit);
      state = AsyncValue.data(scans);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addScan(product) async {
    // Optimistic update — prepend immediately so home screen updates at once
    final optimistic = ScanHistoryItem(
      id: -1,
      barcode: product.barcode,
      name: product.name,
      brand: product.brand ?? '',
      imageUrl: product.imageUrl,
      nutriscore: product.nutriscore,
      calories: product.nutrition.calories,
      scannedAt: DateTime.now(),
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([optimistic, ...current]);

    await _service.addScan(product);
    // Don't fetchRecentScans here — ScannerScreen does it when user comes back
  }
}