import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/health_snapshot_model.dart';
import '../providers/health_provider.dart';

class HealthProgressScreen extends ConsumerStatefulWidget {
  const HealthProgressScreen({super.key});

  @override
  ConsumerState<HealthProgressScreen> createState() =>
      _HealthProgressScreenState();
}

class _HealthProgressScreenState
    extends ConsumerState<HealthProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(healthSnapshotsProvider.notifier).fetchSnapshots());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/health-history'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC6F2D).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left,
                            color: Color(0xFFEC6F2D), size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Health Progress',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tab,
                  labelColor: const Color(0xFFEC6F2D),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFEC6F2D),
                  tabs: const [
                    Tab(text: 'Charts'),
                    Tab(text: 'Baseline vs Now'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ref.watch(healthSnapshotsProvider).when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFEC6F2D))),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final snapshots = state.snapshots;
          final targetWeight = state.targetWeight;
          if (snapshots.isEmpty) return const _EmptyState();
          final chronological = [...snapshots]
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          return TabBarView(
            controller: _tab,
            children: [
              _ChartsTab(
                  snapshots: chronological, targetWeight: targetWeight),
              _BaselineTab(
                  baseline: chronological.first,
                  current: chronological.last,
                  snapshots: chronological),
            ],
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No health snapshots yet',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          SizedBox(height: 4),
          Text('Add a snapshot in Health Profile to start tracking',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Charts tab (NL-51) ────────────────────────────────────────────────────────

class _ChartsTab extends StatefulWidget {
  final List<HealthSnapshot> snapshots;
  final double? targetWeight;
  const _ChartsTab({required this.snapshots, this.targetWeight});

  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  // 3-point moving average
  List<FlSpot> _movingAverage(List<double> values, {int window = 3}) {
    final result = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      final start = (i - window ~/ 2).clamp(0, values.length - 1);
      final end = (i + window ~/ 2).clamp(0, values.length - 1);
      final avg = values.sublist(start, end + 1).reduce((a, b) => a + b) /
          (end - start + 1);
      result.add(FlSpot(i.toDouble(), avg));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weightSnaps =
        widget.snapshots.where((s) => s.weight != null).toList();
    final bmiSnaps = widget.snapshots.where((s) => s.bmi != null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (weightSnaps.isNotEmpty) ...[
          _LineChartCard(
            title: 'Weight (kg)',
            snapshots: weightSnaps,
            getValue: (s) => s.weight!,
            movingAvgSpots: weightSnaps.length >= 3
                ? _movingAverage(weightSnaps.map((s) => s.weight!).toList())
                : null,
            targetY: widget.targetWeight,
            targetLabel: widget.targetWeight != null
                ? 'Target ${widget.targetWeight!.toStringAsFixed(1)} kg'
                : null,
            color: const Color(0xFFEC6F2D),
            unit: 'kg',
          ),
          const SizedBox(height: 16),
        ],
        if (bmiSnaps.isNotEmpty) ...[
          _LineChartCard(
            title: 'BMI',
            snapshots: bmiSnaps,
            getValue: (s) => s.bmi!,
            movingAvgSpots: bmiSnaps.length >= 3
                ? _movingAverage(bmiSnaps.map((s) => s.bmi!).toList())
                : null,
            color: const Color(0xFF5C6BC0),
            unit: '',
            referenceLines: [
              _RefLine(18.5, 'Underweight', Colors.blue.shade300),
              _RefLine(25.0, 'Overweight', Colors.orange),
              _RefLine(30.0, 'Obese', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (weightSnaps.isEmpty && bmiSnaps.isEmpty)
          const Center(
              child: Text('No weight or BMI data.',
                  style: TextStyle(color: Colors.grey))),
      ],
    );
  }
}

class _RefLine {
  final double y;
  final String label;
  final Color color;
  const _RefLine(this.y, this.label, this.color);
}

class _LineChartCard extends StatefulWidget {
  final String title;
  final List<HealthSnapshot> snapshots;
  final double Function(HealthSnapshot) getValue;
  final List<FlSpot>? movingAvgSpots;
  final double? targetY;
  final String? targetLabel;
  final Color color;
  final String unit;
  final List<_RefLine> referenceLines;

  const _LineChartCard({
    required this.title,
    required this.snapshots,
    required this.getValue,
    this.movingAvgSpots,
    this.targetY,
    this.targetLabel,
    required this.color,
    required this.unit,
    this.referenceLines = const [],
  });

  @override
  State<_LineChartCard> createState() => _LineChartCardState();
}

class _LineChartCardState extends State<_LineChartCard> {
  int? _touchedIndex;

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = widget.snapshots;
    final getValue = widget.getValue;
    final color = widget.color;
    final unit = widget.unit;
    final values = snapshots.map(getValue).toList();
    final allY = [...values, if (widget.targetY != null) widget.targetY!];
    final minY = (allY.reduce((a, b) => a < b ? a : b) - 2).clamp(0.0, double.infinity);
    final maxY = allY.reduce((a, b) => a > b ? a : b) + 2;

    final spots = List.generate(
        snapshots.length, (i) => FlSpot(i.toDouble(), values[i]));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2D3142))),
              ),
              if (widget.movingAvgSpots != null)
                Row(children: [
                  Container(
                    width: 12, height: 2,
                    color: color.withOpacity(0.4),
                    margin: const EdgeInsets.only(right: 4),
                  ),
                  const Text('Avg', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Builder(builder: (context) {
              // Build main bar data first so we can reference it in showingTooltipIndicators
              final mainBarData = LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: color,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                    radius: _touchedIndex == i ? 5 : 3,
                    color: color,
                    strokeWidth: _touchedIndex == i ? 2 : 0,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.07),
                ),
              );

              return LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                // showingTooltipIndicators forces tooltip visible after tap
                showingTooltipIndicators: _touchedIndex != null
                    ? [
                        ShowingTooltipIndicators([
                          LineBarSpot(mainBarData, 0, spots[_touchedIndex!]),
                        ])
                      ]
                    : [],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (event is! FlTapUpEvent) return;
                    final spot = response?.lineBarSpots
                        ?.where((s) => s.barIndex == 0)
                        .firstOrNull;
                    setState(() {
                      if (spot == null) {
                        _touchedIndex = null;
                      } else if (_touchedIndex == spot.spotIndex) {
                        _touchedIndex = null;
                      } else {
                        _touchedIndex = spot.spotIndex;
                      }
                    });
                  },
                  getTouchedSpotIndicator: (barData, spotIndexes) =>
                      spotIndexes.map((i) => TouchedSpotIndicatorData(
                            FlLine(
                              color: color.withOpacity(0.25),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                radius: 5,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                          )).toList(),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF2D3142).withOpacity(0.88),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((s) {
                      if (s.barIndex != 0) return null;
                      final date =
                          _formatDate(snapshots[s.spotIndex].recordedAt);
                      return LineTooltipItem(
                        '$date\n',
                        const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w400),
                        children: [
                          TextSpan(
                            text: '${s.y.toStringAsFixed(1)}$unit',
                            style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, _) => Text(
                        val.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: snapshots.length <= 8,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= snapshots.length) {
                          return const SizedBox.shrink();
                        }
                        final dt = snapshots[idx].recordedAt;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${dt.day}/${dt.month}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    ...widget.referenceLines.map((r) => HorizontalLine(
                          y: r.y,
                          color: r.color.withOpacity(0.5),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (_) => r.label,
                            style: TextStyle(
                                fontSize: 9,
                                color: r.color,
                                fontWeight: FontWeight.w600),
                          ),
                        )),
                    if (widget.targetY != null)
                      HorizontalLine(
                        y: widget.targetY!,
                        color: Colors.green.withOpacity(0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 3],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.bottomRight,
                          labelResolver: (_) => widget.targetLabel ?? 'Target',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  mainBarData,
                  if (widget.movingAvgSpots != null)
                    LineChartBarData(
                      spots: widget.movingAvgSpots!,
                      isCurved: true,
                      curveSmoothness: 0.5,
                      color: color.withOpacity(0.35),
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      dashArray: [4, 4],
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            );}),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'First: ${getValue(snapshots.first).toStringAsFixed(1)}$unit',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                'Latest: ${getValue(snapshots.last).toStringAsFixed(1)}$unit',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element — kept for potential reuse
class _ChartTooltip extends StatelessWidget {
  final String date;
  final double value;
  final String unit;
  final Color color;
  const _ChartTooltip(
      {required this.date,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$date — ${value.toStringAsFixed(1)}$unit',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Baseline vs Now tab (NL-52) ───────────────────────────────────────────────

class _BaselineTab extends StatelessWidget {
  final HealthSnapshot baseline;
  final HealthSnapshot current;
  final List<HealthSnapshot> snapshots;
  const _BaselineTab(
      {required this.baseline,
      required this.current,
      required this.snapshots});

  // overall_status: improving | stable | declining
  // Based on weight trend (last 3 vs first 3 snapshots)
  String _overallStatus() {
    final weightSnaps = snapshots.where((s) => s.weight != null).toList();
    if (weightSnaps.length < 2) return 'stable';
    final delta = weightSnaps.last.weight! - weightSnaps.first.weight!;
    // For health in general: losing weight is usually improving (cover most cases)
    // Use ±0.5kg threshold for stable
    if (delta.abs() < 0.5) return 'stable';
    return delta < 0 ? 'improving' : 'declining';
  }

  @override
  Widget build(BuildContext context) {
    final status = _overallStatus();
    final sameSnapshot = baseline.id == current.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CoachingCard(
            status: status,
            baseline: baseline,
            current: current,
            sameSnapshot: sameSnapshot),
        const SizedBox(height: 16),
        _BaselineHeader(baseline: baseline, current: current),
        const SizedBox(height: 16),
        if (baseline.weight != null || current.weight != null)
          _DeltaCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            unit: 'kg',
            baselineValue: baseline.weight,
            currentValue: current.weight,
            lowerIsBetter: true,
          ),
        const SizedBox(height: 12),
        if (baseline.bmi != null || current.bmi != null)
          _DeltaCard(
            icon: Icons.accessibility_new,
            label: 'BMI',
            unit: '',
            baselineValue: baseline.bmi,
            currentValue: current.bmi,
            lowerIsBetter: true,
          ),
        const SizedBox(height: 12),
        if (baseline.dailyCalorieTarget != null ||
            current.dailyCalorieTarget != null)
          _DeltaCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Calorie target',
            unit: 'kcal',
            baselineValue: baseline.dailyCalorieTarget,
            currentValue: current.dailyCalorieTarget,
            lowerIsBetter: false,
          ),
      ],
    );
  }
}

class _CoachingCard extends StatelessWidget {
  final String status; // improving | stable | declining
  final HealthSnapshot baseline;
  final HealthSnapshot current;
  final bool sameSnapshot;
  const _CoachingCard(
      {required this.status,
      required this.baseline,
      required this.current,
      required this.sameSnapshot});

  @override
  Widget build(BuildContext context) {
    if (sameSnapshot) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Only one snapshot recorded. Add more to track your progress.',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final (statusIcon, headline, subtitle, bgColor, borderColor, textColor) =
        switch (status) {
      'improving' => (
          const Icon(Icons.trending_up, size: 28, color: Color(0xFF388E3C)),
          "You're improving",
          _buildSubtitle(baseline, current),
          Colors.green.shade50,
          Colors.green.shade200,
          Colors.green.shade700,
        ),
      'declining' => (
          const Icon(Icons.trending_down, size: 28, color: Color(0xFFD32F2F)),
          "You're slipping",
          _buildSubtitle(baseline, current),
          Colors.red.shade50,
          Colors.red.shade200,
          Colors.red.shade700,
        ),
      _ => (
          const Icon(Icons.trending_flat, size: 28, color: Color(0xFFE65100)),
          'Stable progress',
          _buildSubtitle(baseline, current),
          Colors.orange.shade50,
          Colors.orange.shade200,
          Colors.orange.shade700,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          statusIcon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(HealthSnapshot baseline, HealthSnapshot current) {
    final parts = <String>[];
    if (baseline.weight != null && current.weight != null) {
      final delta = current.weight! - baseline.weight!;
      if (delta.abs() >= 0.1) {
        final sign = delta < 0 ? '' : '+';
        parts.add('$sign${delta.toStringAsFixed(1)} kg since start');
      }
    }
    if (baseline.bmi != null && current.bmi != null) {
      final delta = current.bmi! - baseline.bmi!;
      if (delta.abs() >= 0.1) {
        final sign = delta < 0 ? '' : '+';
        parts.add('BMI $sign${delta.toStringAsFixed(1)}');
      }
    }
    final days =
        current.recordedAt.difference(baseline.recordedAt).inDays;
    if (days > 0) parts.add('over $days days');
    return parts.isEmpty ? 'Keep tracking to see more details' : parts.join(' · ');
  }
}

class _BaselineHeader extends StatelessWidget {
  final HealthSnapshot baseline;
  final HealthSnapshot current;
  const _BaselineHeader({required this.baseline, required this.current});

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final daysDiff =
        current.recordedAt.difference(baseline.recordedAt).inDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Baseline',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(_formatDate(baseline.recordedAt),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
              Text(
                daysDiff > 0 ? '$daysDiff days' : 'Same day',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Now',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(_formatDate(current.recordedAt),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final double? baselineValue;
  final double? currentValue;
  final bool lowerIsBetter;

  const _DeltaCard({
    required this.icon,
    required this.label,
    required this.unit,
    this.baselineValue,
    this.currentValue,
    required this.lowerIsBetter,
  });

  @override
  Widget build(BuildContext context) {
    final hasBase = baselineValue != null;
    final hasCurrent = currentValue != null;
    final hasDelta = hasBase && hasCurrent;
    final delta = hasDelta ? currentValue! - baselineValue! : null;

    Color deltaColor = Colors.grey;
    IconData deltaIcon = Icons.remove;
    if (delta != null && delta.abs() > 0.01) {
      final isPositive = delta > 0;
      final isGood = lowerIsBetter ? !isPositive : isPositive;
      deltaColor =
          isGood ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
      deltaIcon =
          isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEC6F2D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, color: const Color(0xFFEC6F2D), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2D3142))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      hasBase
                          ? '${baselineValue!.toStringAsFixed(1)}$unit'
                          : '—',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          size: 12, color: Colors.grey),
                    ),
                    Text(
                      hasCurrent
                          ? '${currentValue!.toStringAsFixed(1)}$unit'
                          : '—',
                      style: const TextStyle(
                          color: Color(0xFF2D3142),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasDelta)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: deltaColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(deltaIcon, color: deltaColor, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    '${delta!.abs().toStringAsFixed(1)}$unit',
                    style: TextStyle(
                        color: deltaColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
