import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import 'notification_service.dart';

class AdminNotificationService {
  static const _storage = FlutterSecureStorage();
  static const _kLastCountKey = 'admin_last_community_verified_count';
  static const _notificationId = 9001;

  /// Call this when the app resumes. Shows a local notification if
  /// the number of community_verified products increased since last check.
  static Future<void> checkAndNotify() async {
    try {
      final resp = await ApiClient.instance
          .get('/inventory/admin/products/count/');
      final current = (resp.data['community_verified'] as num?)?.toInt() ?? 0;

      final storedStr = await _storage.read(key: _kLastCountKey);
      final last = int.tryParse(storedStr ?? '0') ?? 0;

      await _storage.write(key: _kLastCountKey, value: '$current');

      if (current > last) {
        final diff = current - last;
        await NotificationService.showNotification(
          id: _notificationId,
          title: 'Products ready for review',
          body: diff == 1
              ? '1 product has been community verified and is waiting for your approval.'
              : '$diff products have been community verified and are waiting for your approval.',
          payload: 'admin_review',
        );
      }
    } catch (_) {
      // Silently ignore — user may not be staff or network may be offline
    }
  }

  /// Reset stored count (call after reviewing products).
  static Future<void> resetCount() async {
    await _storage.write(key: _kLastCountKey, value: '0');
  }
}
