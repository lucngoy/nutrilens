import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_profile_model.dart';
import '../models/health_snapshot_model.dart';
import '../models/medical_document_model.dart';
import '../services/health_service.dart';

final healthServiceProvider =
    Provider<HealthService>((ref) => HealthService());

// ── Health Profile Provider ───────────────────────────────────────────────

final healthProfileProvider =
    StateNotifierProvider<HealthProfileNotifier, AsyncValue<HealthProfile?>>(
  (ref) => HealthProfileNotifier(ref.read(healthServiceProvider)),
);

class HealthProfileNotifier
    extends StateNotifier<AsyncValue<HealthProfile?>> {
  final HealthService _service;

  HealthProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getProfile();
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(HealthProfile profile) async {
    try {
      final updated = await _service.updateProfile(profile);
      state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }
}

// ── Health Snapshots Provider ─────────────────────────────────────────────

final healthSnapshotsProvider =
    StateNotifierProvider<HealthSnapshotsNotifier,
        AsyncValue<List<HealthSnapshot>>>(
  (ref) => HealthSnapshotsNotifier(ref.read(healthServiceProvider)),
);

class HealthSnapshotsNotifier
    extends StateNotifier<AsyncValue<List<HealthSnapshot>>> {
  final HealthService _service;

  HealthSnapshotsNotifier(this._service)
      : super(const AsyncValue.data([]));

  Future<void> fetchSnapshots() async {
    state = const AsyncValue.loading();
    try {
      final snapshots = await _service.getSnapshots();
      state = AsyncValue.data(snapshots);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addSnapshot({
    double? weight,
    double? bmi,
    double? dailyCalorieTarget,
    String notes = '',
  }) async {
    try {
      final snapshot = await _service.addSnapshot(
        weight: weight,
        bmi: bmi,
        dailyCalorieTarget: dailyCalorieTarget,
        notes: notes,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([snapshot, ...current]);
    } catch (e) {
      rethrow;
    }
  }
}

// ── Medical Documents Provider ────────────────────────────────────────────

final medicalDocumentsProvider =
    StateNotifierProvider<MedicalDocumentsNotifier,
        AsyncValue<List<MedicalDocument>>>(
  (ref) => MedicalDocumentsNotifier(ref.read(healthServiceProvider)),
);

class MedicalDocumentsNotifier
    extends StateNotifier<AsyncValue<List<MedicalDocument>>> {
  final HealthService _service;

  MedicalDocumentsNotifier(this._service)
      : super(const AsyncValue.data([]));

  Future<void> fetchDocuments() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _service.getDocuments();
      state = AsyncValue.data(docs);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> uploadDocument({
    required File file,
    required String title,
    required String documentType,
    String notes = '',
  }) async {
    try {
      final doc = await _service.uploadDocument(
        file: file,
        title: title,
        documentType: documentType,
        notes: notes,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([doc, ...current]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDocument(int id, {required String title, required String notes}) async {
    try {
      final updated = await _service.updateDocument(id, title: title, notes: notes);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
          current.map((d) => d.id == id ? updated : d).toList());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _service.deleteDocument(id);
      final current = state.valueOrNull ?? [];
      state =
          AsyncValue.data(current.where((d) => d.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}