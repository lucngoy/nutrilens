import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_report_model.dart';
import '../providers/food_intake_provider.dart';

Color _statusColor(String status) => switch (status) {
  'on_track' => const Color(0xFF4CAF50),
  'warning' => const Color(0xFFFF9800),
  'exceeded' => const Color(0xFFF44336),
  _ => const Color(0xFFBDBDBD),
};

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  // Offset in months from current (0 = this month, -1 = last month…)
  int _monthOffset = 0;

  String get _monthKey {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + _monthOffset, 1);
    return '${target.year}-${target.month.toString().padLeft(2, '0')}';
  }

  bool get _isCurrentMonth => _monthOffset == 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(monthlyReportProvider.notifier).fetch(month: _monthKey));
  }

  void _goToMonth(int offset) {
    setState(() => _monthOffset += offset);
    ref.read(monthlyReportProvider.notifier).fetch(month: _monthKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monthlyReportProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Monthly Report',
            style: TextStyle(
                color: Color(0xFF2D3142), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: Column(
        children: [
          _MonthBar(
            monthKey: _monthKey,
            isCurrentMonth: _isCurrentMonth,
            onPrev: () => _goToMonth(-1),
            onNext: _isCurrentMonth ? null : () => _goToMonth(1),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEC6F2D))),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (report) {
                if (report == null) return const SizedBox.shrink();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MonthTrendCard(report: report),
                    const SizedBox(height: 16),
                    _WeekBarChart(weeks: report.weeks, dailyTarget: report.summary.calorieTarget),
                    const SizedBox(height: 16),
                    _MonthStatsCard(summary: report.summary),
                    const SizedBox(height: 16),
                    _WeekBreakdownList(weeks: report.weeks),
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

// ── Month navigation bar ──────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  final String monthKey;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthBar({
    required this.monthKey,
    required this.isCurrentMonth,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label = isCurrentMonth ? 'This month — $monthKey' : monthKey;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: const Color(0xFF2D3142),
          ),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D3142))),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null
                    ? const Color(0xFF2D3142)
                    : Colors.grey.shade300),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Trend card ────────────────────────────────────────────────────────────────

class _MonthTrendCard extends StatelessWidget {
  final MonthlyReport report;
  const _MonthTrendCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = report.summary;
    final (icon, _) = switch (s.trend) {
      'up' => (Icons.trending_up, Colors.orange.shade700),
      'down' => (Icons.trending_down, Colors.green.shade600),
      _ => (Icons.trending_flat, const Color(0xFF2D3142)),
    };
    final logPct = s.daysInMonth > 0
        ? (s.daysLogged / s.daysInMonth * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.monthName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${s.avgCalories.toInt()} kcal / day',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    if (s.calorieTarget != null)
                      Text('Target: ${s.calorieTarget!.toInt()} kcal',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(s.trendLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$logPct%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const Text('logged',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${s.daysLogged} / ${s.daysInMonth} days',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.daysInMonth > 0
                  ? (s.daysLogged / s.daysInMonth).clamp(0.0, 1.0)
                  : 0,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week bar chart ────────────────────────────────────────────────────────────

class _WeekBarChart extends StatefulWidget {
  final List<MonthlyWeek> weeks;
  final double? dailyTarget;
  const _WeekBarChart({required this.weeks, this.dailyTarget});

  @override
  State<_WeekBarChart> createState() => _WeekBarChartState();
}

class _WeekBarChartState extends State<_WeekBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final maxY = widget.weeks.fold(
        0.0, (m, w) => w.avgCaloriesPerDay > m ? w.avgCaloriesPerDay : m);
    final targetY = widget.dailyTarget;
    final chartMax =
        ((maxY > (targetY ?? 0) ? maxY : (targetY ?? 0)) * 1.2).ceilToDouble();

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
          const Text('Avg calories per week',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          if (_touchedIndex != null)
            _WeekTooltip(week: widget.weeks[_touchedIndex!]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: chartMax > 0 ? chartMax : 2500,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    getTooltipItem: (_, __, ___, ____) => null,
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    setState(() =>
                        _touchedIndex = response.spot!.touchedBarGroupIndex);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.weeks.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('W${idx + 1}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax > 0 ? chartMax / 4 : 500,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.weeks.length, (i) {
                  final w = widget.weeks[i];
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: w.hasData ? w.avgCaloriesPerDay : 0,
                        color: _statusColor(w.status)
                            .withOpacity(isTouched ? 1.0 : 0.85),
                        width: isTouched ? 28 : 22,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMax > 0 ? chartMax : 2500,
                          color: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  );
                }),
                extraLinesData: targetY != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: targetY,
                          color: const Color(0xFFEC6F2D),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (_) => 'target',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFEC6F2D),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ])
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekTooltip extends StatelessWidget {
  final MonthlyWeek week;
  const _WeekTooltip({required this.week});

  static const _statusLabels = {
    'on_track': 'On track',
    'warning': 'Warning',
    'exceeded': 'Exceeded',
    'no_data': 'No data',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(week.status);
    final statusLabel = _statusLabels[week.status] ?? week.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(week.week,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(
            week.hasData
                ? '${week.avgCaloriesPerDay.toInt()} kcal/day'
                    ' · ${week.daysLogged}/${week.daysInWeek} days'
                    '${week.adherencePct != null ? ' · ${week.adherencePct!.toInt()}%' : ''}'
                : 'No data',
            style: TextStyle(color: color, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Monthly stats card ────────────────────────────────────────────────────────

class _MonthStatsCard extends StatelessWidget {
  final MonthlySummary summary;
  const _MonthStatsCard({required this.summary});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('Month overview',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 14),
          Row(
            children: [
              _BigStat(
                  label: 'On track',
                  value: '${summary.daysOnTrack}',
                  unit: 'days',
                  color: const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _BigStat(
                  label: 'Exceeded',
                  value: '${summary.daysExceeded}',
                  unit: 'days',
                  color: const Color(0xFFF44336)),
              const SizedBox(width: 12),
              _BigStat(
                  label: 'Total',
                  value: '${(summary.totalCalories / 1000).toStringAsFixed(1)}k',
                  unit: 'kcal',
                  color: const Color(0xFFEC6F2D)),
            ],
          ),
          if (summary.bestDay != null || summary.worstDay != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                if (summary.bestDay != null)
                  Expanded(
                    child: _HighlightRow(
                        label: 'Best day',
                        value: _formatDate(summary.bestDay),
                        icon: Icons.star_outline,
                        color: const Color(0xFF4CAF50)),
                  ),
                if (summary.worstDay != null)
                  Expanded(
                    child: _HighlightRow(
                        label: 'Worst day',
                        value: _formatDate(summary.worstDay),
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFF44336)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _BigStat(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: value,
                      style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          color: color.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HighlightRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 10)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Week-by-week breakdown ────────────────────────────────────────────────────

class _WeekBreakdownList extends StatelessWidget {
  final List<MonthlyWeek> weeks;
  const _WeekBreakdownList({required this.weeks});

  @override
  Widget build(BuildContext context) {
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
          const Text('Weekly detail',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          ...List.generate(weeks.length, (i) => _WeekRow(
              week: weeks[i], label: 'W${i + 1}')),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final MonthlyWeek week;
  final String label;
  const _WeekRow({required this.week, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(week.status);
    final pct = week.calorieTargetWeek != null && week.calorieTargetWeek! > 0
        ? (week.totalCalories / week.calorieTargetWeek!).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: week.hasData ? pct : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  week.hasData
                      ? '${week.avgCaloriesPerDay.toInt()} kcal/d'
                      : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: week.hasData ? color : Colors.grey),
                ),
              ),
            ],
          ),
          if (week.hasData)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 2),
              child: Text(
                '${week.weekStart} → ${week.weekEnd}  ·  ${week.daysLogged}/${week.daysInWeek} days logged',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
