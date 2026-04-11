import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_provider.dart';
import '../models/health_snapshot_model.dart';

class HealthHistoryScreen extends ConsumerStatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  ConsumerState<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends ConsumerState<HealthHistoryScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(healthSnapshotsProvider.notifier).fetchSnapshots());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthSnapshotsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/profile'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: primaryColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Health History',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
              ],
            ),
          ),

          // Body
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (snapshots) => snapshots.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshots.length,
                      itemBuilder: (_, i) =>
                          _SnapshotCard(snapshot: snapshots[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No history yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('Update your health profile to start tracking',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final HealthSnapshot snapshot;
  const _SnapshotCard({required this.snapshot});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            _formatDate(snapshot.recordedAt),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.04),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              if (snapshot.weight != null)
                _StatChip(
                  icon: Icons.monitor_weight_outlined,
                  label: '${snapshot.weight!.toStringAsFixed(1)} kg',
                ),
              if (snapshot.bmi != null) ...[
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.analytics_outlined,
                  label: 'BMI ${snapshot.bmi!.toStringAsFixed(1)}',
                  color: _bmiColor(snapshot.bmi!),
                ),
              ],
              if (snapshot.dailyCalorieTarget != null) ...[
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.local_fire_department_outlined,
                  label: '${snapshot.dailyCalorieTarget!.toStringAsFixed(0)} kcal',
                ),
              ],
            ],
          ),
          if (snapshot.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(snapshot.notes,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ·  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return const Color(0xFF27AE60);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFEC6F2D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}
