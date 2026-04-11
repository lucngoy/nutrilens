import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/analysis_model.dart';
import '../services/analysis_service.dart';

final analysisProvider = StateNotifierProvider.autoDispose<
    AnalysisNotifier, AsyncValue<AnalysisResult?>>((ref) {
  return AnalysisNotifier(AnalysisService());
});

class AnalysisNotifier extends StateNotifier<AsyncValue<AnalysisResult?>> {
  final AnalysisService _service;

  AnalysisNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> analyze(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.analyzeProduct(product);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
