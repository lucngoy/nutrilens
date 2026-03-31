import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../features/inventory/models/inventory_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static void Function(String?)? onNotificationTap;

  static Future<void> init({void Function(String?)? onTap}) async {
    if (_initialized) return;

    onNotificationTap = onTap;

    try {
      tz.initializeTimeZones();
    } catch (_) {
      // timezone init failed — scheduled notifications will not work
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String payload = 'inventory',
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrilens_alerts',
          'NutriLens Alerts',
          channelDescription: 'Inventory and stock alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrilens_daily',
          'NutriLens Daily Alerts',
          channelDescription: 'Daily inventory reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> checkInventoryAlerts(
      List<InventoryItem> items) async {
    final lowStock = items.where((i) => i.isLowStock).toList();
    final expiringSoon = items.where((i) {
      if (i.expirationDate == null) return false;
      final daysLeft = i.expirationDate!.difference(DateTime.now()).inDays;
      return daysLeft <= 3 && daysLeft >= 0;
    }).toList();
    final expired = items.where((i) {
      if (i.expirationDate == null) return false;
      return i.expirationDate!.isBefore(DateTime.now());
    }).toList();

    if (lowStock.isNotEmpty) {
      await showNotification(
        id: 1,
        title: 'NutriLens — ⚠️ Low Stock Alert',
        body: lowStock.length == 1
            ? '${lowStock.first.name} is running low!'
            : '${lowStock.length} items are running low in your inventory.',
      );
    }

    if (expiringSoon.isNotEmpty) {
      await showNotification(
        id: 2,
        title: 'NutriLens — 📅 Expiring Soon',
        body: expiringSoon.length == 1
            ? '${expiringSoon.first.name} expires in ${expiringSoon.first.expirationDate!.difference(DateTime.now()).inDays} days!'
            : '${expiringSoon.length} products are expiring soon.',
      );
    }

    if (expired.isNotEmpty) {
      await showNotification(
        id: 3,
        title: 'NutriLens — 🚨 Expired Products',
        body: expired.length == 1
            ? '${expired.first.name} has expired. Please remove it.'
            : '${expired.length} products have expired in your inventory.',
      );
    }

    if (lowStock.isNotEmpty || expiringSoon.isNotEmpty) {
      await scheduleDailyNotification(
        id: 100,
        title: 'NutriLens — 🛒 Daily Check',
        body: _buildDailySummary(lowStock, expiringSoon, expired),
        hour: 9,
        minute: 0,
      );
    }
  }

  static String _buildDailySummary(
    List<InventoryItem> lowStock,
    List<InventoryItem> expiringSoon,
    List<InventoryItem> expired,
  ) {
    final parts = <String>[];
    if (lowStock.isNotEmpty) parts.add('${lowStock.length} items low on stock');
    if (expiringSoon.isNotEmpty) parts.add('${expiringSoon.length} expiring soon');
    if (expired.isNotEmpty) parts.add('${expired.length} expired');
    return parts.join(' • ');
  }
}
