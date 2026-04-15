import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/health_profile_model.dart';
import '../models/health_snapshot_model.dart';
import '../models/medical_document_model.dart';

class HealthService {
  final _dio = ApiClient.instance;

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<HealthProfile> getProfile() async {
    try {
      final response = await _dio.get('/users/profile/');
      return HealthProfile.fromJson(response.data['profile']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<HealthProfile> updateProfile(HealthProfile profile) async {
    try {
      final response = await _dio.patch('/users/profile/', data: {
        'profile': profile.toJson(),
      });
      return HealthProfile.fromJson(response.data['profile']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Health Snapshots (NL-28 / NL-31) ─────────────────────────────────────

  Future<({List<HealthSnapshot> snapshots, double? targetWeight})> getSnapshots({int? limit}) async {
    try {
      final params = limit != null ? {'limit': limit} : <String, dynamic>{};
      final response = await _dio.get('/users/health/snapshots/', queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      final snapshots = (data['snapshots'] as List)
          .map((e) => HealthSnapshot.fromJson(e))
          .toList();
      final targetWeight = (data['target_weight'] as num?)?.toDouble();
      return (snapshots: snapshots, targetWeight: targetWeight);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<HealthSnapshot> addSnapshot({
    double? weight,
    double? bmi,
    double? dailyCalorieTarget,
    String notes = '',
  }) async {
    try {
      final response = await _dio.post('/users/health/snapshots/', data: {
        'weight': weight,
        'bmi': bmi,
        'daily_calorie_target': dailyCalorieTarget,
        'notes': notes,
      });
      return HealthSnapshot.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Medical Documents (NL-29 / NL-30) ────────────────────────────────────

  Future<List<MedicalDocument>> getDocuments() async {
    try {
      final response = await _dio.get('/users/health/documents/');
      return (response.data as List)
          .map((e) => MedicalDocument.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MedicalDocument> uploadDocument({
    required File file,
    required String title,
    required String documentType,
    String notes = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'document_type': documentType,
        'notes': notes,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await _dio.post(
        '/users/health/documents/upload/',
        data: formData,
      );
      return MedicalDocument.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MedicalDocument> updateDocument(int id, {required String title, required String notes}) async {
    try {
      final response = await _dio.patch(
        '/users/health/documents/$id/',
        data: {'title': title, 'notes': notes},
      );
      return MedicalDocument.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _dio.delete('/users/health/documents/$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handler ─────────────────────────────────────────────────────────

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['profile'] != null) {
        return data['profile'].toString();
      }
      return data.toString();
    }
    return 'Unable to connect. Please check your connection.';
  }
}
