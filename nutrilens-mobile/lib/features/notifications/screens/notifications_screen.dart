import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  static const _storage = FlutterSecureStorage();

  bool _mealReminders = true;
  bool _budgetAlerts = true;
  bool _inventoryAlerts = true;
  bool _healthTrendAlerts = true;
  bool _loading = true;

  // Meal reminder times
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meal = await _storage.read(key: 'notif_meal_reminders');
    final budget = await _storage.read(key: 'notif_budget_alerts');
    final inventory = await _storage.read(key: 'notif_inventory_alerts');
    final health = await _storage.read(key: 'notif_health_trend_alerts');
    final breakfast = await _storage.read(key: 'notif_breakfast_time');
    final lunch = await _storage.read(key: 'notif_lunch_time');
    final dinner = await _storage.read(key: 'notif_dinner_time');

    setState(() {
      _mealReminders = meal != 'false';
      _budgetAlerts = budget != 'false';
      _inventoryAlerts = inventory != 'false';
      _healthTrendAlerts = health != 'false';
      if (breakfast != null) _breakfastTime = _parseTime(breakfast);
      if (lunch != null) _lunchTime = _parseTime(lunch);
      if (dinner != null) _dinnerTime = _parseTime(dinner);
      _loading = false;
    });
  }

  TimeOfDay _parseTime(String stored) {
    final parts = stored.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(TimeOfDay current, Future<void> Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) await onPicked(picked);
  }

  Future<void> _scheduleAll() async {
    await NotificationService.scheduleDailyNotification(
        id: 120, title: 'NutriLens — Breakfast',
        body: "Don't forget to log your breakfast!",
        hour: _breakfastTime.hour, minute: _breakfastTime.minute);
    await NotificationService.scheduleDailyNotification(
        id: 121, title: 'NutriLens — Lunch',
        body: "Have you logged your lunch today?",
        hour: _lunchTime.hour, minute: _lunchTime.minute);
    await NotificationService.scheduleDailyNotification(
        id: 122, title: 'NutriLens — Dinner',
        body: "Don't forget to log your dinner!",
        hour: _dinnerTime.hour, minute: _dinnerTime.minute);
  }

  Future<void> _setMealReminders(bool value) async {
    setState(() => _mealReminders = value);
    await _storage.write(key: 'notif_meal_reminders', value: '$value');
    if (value) {
      await _scheduleAll();
    } else {
      await NotificationService.cancel(120);
      await NotificationService.cancel(121);
      await NotificationService.cancel(122);
    }
  }

  Future<void> _setBreakfastTime(TimeOfDay t) async {
    setState(() => _breakfastTime = t);
    await _storage.write(key: 'notif_breakfast_time', value: _formatTime(t));
    if (_mealReminders) {
      await NotificationService.cancel(120);
      await NotificationService.scheduleDailyNotification(
          id: 120, title: 'NutriLens — Breakfast',
          body: "Don't forget to log your breakfast!",
          hour: t.hour, minute: t.minute);
    }
  }

  Future<void> _setLunchTime(TimeOfDay t) async {
    setState(() => _lunchTime = t);
    await _storage.write(key: 'notif_lunch_time', value: _formatTime(t));
    if (_mealReminders) {
      await NotificationService.cancel(121);
      await NotificationService.scheduleDailyNotification(
          id: 121, title: 'NutriLens — Lunch',
          body: "Have you logged your lunch today?",
          hour: t.hour, minute: t.minute);
    }
  }

  Future<void> _setDinnerTime(TimeOfDay t) async {
    setState(() => _dinnerTime = t);
    await _storage.write(key: 'notif_dinner_time', value: _formatTime(t));
    if (_mealReminders) {
      await NotificationService.cancel(122);
      await NotificationService.scheduleDailyNotification(
          id: 122, title: 'NutriLens — Dinner',
          body: "Don't forget to log your dinner!",
          hour: t.hour, minute: t.minute);
    }
  }

  Future<void> _toggle(String key, bool value, void Function(bool) setter) async {
    setState(() => setter(value));
    await _storage.write(key: key, value: '$value');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: primaryColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              ],
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: primaryColor)))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Section(
                    title: 'MEALS',
                    children: [
                      _ToggleTile(
                        icon: Icons.restaurant_outlined,
                        iconColor: primaryColor,
                        title: 'Meal reminders',
                        subtitle: 'Daily reminders to log your meals',
                        value: _mealReminders,
                        onChanged: _setMealReminders,
                      ),
                      if (_mealReminders) ...[
                        const Divider(height: 1, indent: 56),
                        _TimeTile(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Breakfast',
                          time: _breakfastTime,
                          onTap: () => _pickTime(_breakfastTime, _setBreakfastTime),
                        ),
                        const Divider(height: 1, indent: 56),
                        _TimeTile(
                          icon: Icons.light_mode_outlined,
                          label: 'Lunch',
                          time: _lunchTime,
                          onTap: () => _pickTime(_lunchTime, _setLunchTime),
                        ),
                        const Divider(height: 1, indent: 56),
                        _TimeTile(
                          icon: Icons.nights_stay_outlined,
                          label: 'Dinner',
                          time: _dinnerTime,
                          onTap: () => _pickTime(_dinnerTime, _setDinnerTime),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'HEALTH',
                    children: [
                      _ToggleTile(
                        icon: Icons.monitor_heart_outlined,
                        iconColor: const Color(0xFFE74C3C),
                        title: 'Abnormal health trends',
                        subtitle: 'Alert when weight or BMI evolves unexpectedly',
                        value: _healthTrendAlerts,
                        onChanged: (v) => _toggle('notif_health_trend_alerts', v,
                            (val) => _healthTrendAlerts = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'BUDGET & INVENTORY',
                    children: [
                      _ToggleTile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF27AE60),
                        title: 'Budget alerts',
                        subtitle: 'Notify when spending pace is too fast',
                        value: _budgetAlerts,
                        onChanged: (v) => _toggle('notif_budget_alerts', v,
                            (val) => _budgetAlerts = val),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ToggleTile(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF2980B9),
                        title: 'Inventory alerts',
                        subtitle: 'Low stock, expiring and expired items',
                        value: _inventoryAlerts,
                        onChanged: (v) => _toggle('notif_inventory_alerts', v,
                            (val) => _inventoryAlerts = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Notifications are delivered as local alerts on your device. No account data is sent to third parties.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.grey, letterSpacing: 0.5)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.iconColor,
      required this.title, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFEC6F2D),
        ),
      ],
    ),
  );
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.icon, required this.label,
      required this.time, required this.onTap});

  String get _display {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black54, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
          ),
          Text(_display,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEC6F2D))),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    ),
  );
}
