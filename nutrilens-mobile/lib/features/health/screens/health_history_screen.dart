import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/health_provider.dart';
import '../models/health_snapshot_model.dart';

enum _ChartMetric { weight, bmi }

class HealthHistoryScreen extends ConsumerStatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  ConsumerState<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends ConsumerState<HealthHistoryScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  _ChartMetric _metric = _ChartMetric.weight;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(healthSnapshotsProvider.notifier).fetchSnapshots());
  }

  @override
  Widget build(BuildContext context) {
    final healthProfile = ref.watch(healthProfileProvider).valueOrNull;
    final snapshotsState = ref.watch(healthSnapshotsProvider);

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
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/profile'),
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

          Expanded(
            child: snapshotsState.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryColor)),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: Colors.red))),
              data: (snapshots) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Current summary ───────────────────────────────────────
                  _SummaryCard(
                    weight: healthProfile?.weight,
                    bmi: healthProfile?.bmi,
                    calorieTarget: healthProfile?.dailyCalorieTarget,
                  ),
                  const SizedBox(height: 16),

                  // ── Chart ─────────────────────────────────────────────────
                  if (snapshots.length >= 2) ...[
                    _ChartCard(
                      snapshots: snapshots,
                      metric: _metric,
                      onMetricChanged: (m) => setState(() => _metric = m),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── History list ──────────────────────────────────────────
                  if (snapshots.isEmpty)
                    _buildEmpty()
                  else ...[
                    const Text('SNAPSHOTS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.08)),
                    const SizedBox(height: 12),
                    ...List.generate(snapshots.length, (i) {
                      final prev =
                          i < snapshots.length - 1 ? snapshots[i + 1] : null;
                      return _SnapshotCard(
                          snapshot: snapshots[i], previous: prev);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 56, color: Colors.grey.shade300),
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
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double? weight;
  final double? bmi;
  final double? calorieTarget;

  const _SummaryCard({this.weight, this.bmi, this.calorieTarget});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.08)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _SummaryStat(
                      label: 'Weight',
                      value: weight != null
                          ? '${weight!.toStringAsFixed(1)} kg'
                          : '—')),
              Expanded(
                  child: _SummaryStat(
                      label: 'BMI',
                      value: bmi != null ? bmi!.toStringAsFixed(1) : '—')),
              Expanded(
                  child: _SummaryStat(
                      label: 'Target',
                      value: calorieTarget != null
                          ? '${calorieTarget!.toStringAsFixed(0)} kcal'
                          : '—')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }
}

// ── Chart Card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<HealthSnapshot> snapshots;
  final _ChartMetric metric;
  final ValueChanged<_ChartMetric> onMetricChanged;

  const _ChartCard({
    required this.snapshots,
    required this.metric,
    required this.onMetricChanged,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    // Snapshots are newest-first — reverse for chart (oldest left)
    final ordered = snapshots.reversed.toList();

    final spots = <FlSpot>[];
    for (var i = 0; i < ordered.length; i++) {
      final val = metric == _ChartMetric.weight
          ? ordered[i].weight
          : ordered[i].bmi;
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    final values = spots.map((s) => s.y).toList();
    final minY = values.isNotEmpty
        ? (values.reduce((a, b) => a < b ? a : b) - 1).floorToDouble()
        : 0.0;
    final maxY = values.isNotEmpty
        ? (values.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble()
        : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(
            children: [
              const Text('EVOLUTION',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.08)),
              const Spacer(),
              _MetricToggle(
                label: 'Weight',
                selected: metric == _ChartMetric.weight,
                onTap: () => onMetricChanged(_ChartMetric.weight),
              ),
              const SizedBox(width: 8),
              _MetricToggle(
                label: 'BMI',
                selected: metric == _ChartMetric.bmi,
                onTap: () => onMetricChanged(_ChartMetric.bmi),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          spots.length < 2
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Not enough data for this metric',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                )
              : SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF0F0F0),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (val, _) => Text(
                              val.toStringAsFixed(
                                  metric == _ChartMetric.bmi ? 1 : 0),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= ordered.length) {
                                return const SizedBox();
                              }
                              final dt = ordered[idx].recordedAt;
                              return Text(
                                '${dt.day}/${dt.month}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 3.5,
                              color: primaryColor,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: primaryColor.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricToggle(
      {required this.label, required this.selected, required this.onTap});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primaryColor : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey)),
      ),
    );
  }
}

// ── Snapshot Card ─────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final HealthSnapshot snapshot;
  final HealthSnapshot? previous;

  const _SnapshotCard({required this.snapshot, this.previous});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    final weightDelta = (snapshot.weight != null && previous?.weight != null)
        ? snapshot.weight! - previous!.weight!
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + source badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(snapshot.recordedAt),
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: snapshot.isAuto
                      ? primaryColor.withOpacity(0.08)
                      : const Color(0xFF3498DB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  snapshot.isAuto ? 'Auto' : 'Manual',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: snapshot.isAuto
                          ? primaryColor
                          : const Color(0xFF3498DB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (snapshot.weight != null)
                _StatChip(
                  icon: Icons.monitor_weight_outlined,
                  label: '${snapshot.weight!.toStringAsFixed(1)} kg',
                  delta: weightDelta,
                ),
              if (snapshot.bmi != null)
                _StatChip(
                  icon: Icons.analytics_outlined,
                  label: 'BMI ${snapshot.bmi!.toStringAsFixed(1)}',
                  color: _bmiColor(snapshot.bmi!),
                ),
              if (snapshot.dailyCalorieTarget != null)
                _StatChip(
                  icon: Icons.local_fire_department_outlined,
                  label:
                      '${snapshot.dailyCalorieTarget!.toStringAsFixed(0)} kcal',
                ),
            ],
          ),

          if (snapshot.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(snapshot.notes,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
  final double? delta;

  const _StatChip({required this.icon, required this.label, this.color, this.delta});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEC6F2D);
    final c = color ?? primaryColor;

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
          if (delta != null) ...[
            const SizedBox(width: 4),
            Text(
              '${delta! > 0 ? '↑' : '↓'} ${delta!.abs().toStringAsFixed(1)}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: delta! < 0 ? const Color(0xFF27AE60) : Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
