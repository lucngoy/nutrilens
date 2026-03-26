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

  ScanHistoryNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> fetchRecentScans({int limit = 10}) async {
    state = const AsyncValue.loading();
    try {
      final scans = await _service.getRecentScans(limit: limit);
      state = AsyncValue.data(scans);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addScan(product) async {
    await _service.addScan(product);
    await fetchRecentScans();
  }
}