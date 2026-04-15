import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/weekly_report_model.dart';
import '../providers/food_intake_provider.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  static const _primary = Color(0xFFEC6F2D);

  // Current ISO week offset from today (0 = this week, -1 = last week, …)
  int _weekOffset = 0;

  String get _weekKey {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final target = monday.add(Duration(days: _weekOffset * 7));
    // ISO week format
    final year = _isoYear(target);
    final week = _isoWeek(target);
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  bool get _isCurrentWeek => _weekOffset == 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(weeklyReportProvider.notifier).fetch(week: _weekKey));
  }

  void _goToWeek(int offset) {
    setState(() => _weekOffset += offset);
    ref.read(weeklyReportProvider.notifier).fetch(week: _weekKey);
  }

  // ISO week number calculation
  int _isoWeek(DateTime date) {
    final jan4 = DateTime(date.year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    final diff = date.difference(startOfWeek1).inDays;
    if (diff < 0) return _isoWeek(DateTime(date.year - 1, 12, 31));
    return (diff ~/ 7) + 1;
  }

  int _isoYear(DateTime date) {
    final week = _isoWeek(date);
    if (week >= 52 && date.month == 1) return date.year - 1;
    if (week == 1 && date.month == 12) return date.year + 1;
    return date.year;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklyReportProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Weekly Report',
            style: TextStyle(
                color: Color(0xFF2D3142), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/monthly-report'),
            icon: const Icon(Icons.calendar_month, size: 16, color: Color(0xFFEC6F2D)),
            label: const Text('Monthly',
                style: TextStyle(color: Color(0xFFEC6F2D), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekBar(
            weekKey: _weekKey,
            isCurrentWeek: _isCurrentWeek,
            onPrev: () => _goToWeek(-1),
            onNext: _isCurrentWeek ? null : () => _goToWeek(1),
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
                    _TrendCard(summary: report.summary),
                    const SizedBox(height: 16),
                    _BarChartCard(days: report.days, target: report.summary.calorieTarget),
                    const SizedBox(height: 16),
                    _SummaryStatsCard(summary: report.summary),
                    const SizedBox(height: 16),
                    _DayBreakdownList(days: report.days),
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

// ── Week navigation bar ───────────────────────────────────────────────────────

class _WeekBar extends StatelessWidget {
  final String weekKey;
  final bool isCurrentWeek;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _WeekBar({
    required this.weekKey,
    required this.isCurrentWeek,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label = isCurrentWeek ? 'This week — $weekKey' : weekKey;
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

class _TrendCard extends StatelessWidget {
  final WeeklySummary summary;
  const _TrendCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final (icon, trendColor) = switch (summary.trend) {
      'up' => (Icons.trending_up, Colors.orange.shade700),
      'down' => (Icons.trending_down, Colors.green.shade600),
      _ => (Icons.trending_flat, const Color(0xFF2D3142)),
    };

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${summary.avgCalories.toInt()} kcal / day',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    summary.calorieTarget != null
                        ? 'Target: ${summary.calorieTarget!.toInt()} kcal'
                        : 'Weekly average',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(summary.trendLabel,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _StatPill('${summary.daysOnTrack}', 'on track', Colors.green.shade300),
              const SizedBox(height: 6),
              _StatPill('${summary.daysExceeded}', 'exceeded', Colors.red.shade300),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$value d $label',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

Color _statusColor(String status) => switch (status) {
  'on_track' => const Color(0xFF4CAF50),
  'warning' => const Color(0xFFFF9800),
  'exceeded' => const Color(0xFFF44336),
  _ => const Color(0xFFBDBDBD),
};

class _BarChartCard extends StatefulWidget {
  final List<WeeklyDay> days;
  final double? target;
  const _BarChartCard({required this.days, this.target});

  @override
  State<_BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<_BarChartCard> {
  int? _touchedIndex;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxY = widget.days.fold(0.0, (m, d) => d.totalCalories > m ? d.totalCalories : m);
    final targetY = widget.target;
    final chartMax = ((maxY > (targetY ?? 0) ? maxY : (targetY ?? 0)) * 1.2).ceilToDouble();

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
          const Text('Calories per day',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          if (_touchedIndex != null)
            _Tooltip(day: widget.days[_touchedIndex!]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
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
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_dayLabels[idx],
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax > 0 ? chartMax / 4 : 500,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.days.length, (i) {
                  final day = widget.days[i];
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: day.hasData ? day.totalCalories : 0,
                        color: _statusColor(day.status).withOpacity(isTouched ? 1.0 : 0.85),
                        width: isTouched ? 22 : 18,
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

class _Tooltip extends StatelessWidget {
  final WeeklyDay day;
  const _Tooltip({required this.day});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _statusLabels = {
    'on_track': 'On track',
    'warning': 'Warning',
    'exceeded': 'Exceeded',
    'no_data': 'No data',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(day.status);
    final dayLabel = _dayLabels[day.weekday];
    final statusLabel = _statusLabels[day.status] ?? day.status;
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
          Text(dayLabel,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(
            day.hasData
                ? '${day.totalCalories.toInt()} kcal'
                    '${day.calorieTarget != null ? ' / ${day.calorieTarget!.toInt()}' : ''}'
                    '${day.adherencePct != null ? '  ·  ${day.adherencePct!.toInt()}%' : ''}'
                : 'No data logged',
            style: TextStyle(color: color, fontSize: 12),
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
                    color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Summary stats ─────────────────────────────────────────────────────────────

class _SummaryStatsCard extends StatelessWidget {
  final WeeklySummary summary;
  const _SummaryStatsCard({required this.summary});

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
          const Text('Week breakdown',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatBox('On track', '${summary.daysOnTrack}d', const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              _StatBox('Warning', '${summary.daysWarning}d', const Color(0xFFFF9800)),
              const SizedBox(width: 8),
              _StatBox('Exceeded', '${summary.daysExceeded}d', const Color(0xFFF44336)),
              const SizedBox(width: 8),
              _StatBox('No data', '${summary.daysNoData}d', const Color(0xFFBDBDBD)),
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
                    child: _DayHighlight(
                        label: 'Best day',
                        date: summary.bestDay!,
                        icon: Icons.star_outline,
                        color: const Color(0xFF4CAF50)),
                  ),
                if (summary.worstDay != null)
                  Expanded(
                    child: _DayHighlight(
                        label: 'Worst day',
                        date: summary.worstDay!,
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DayHighlight extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final Color color;
  const _DayHighlight(
      {required this.label,
      required this.date,
      required this.icon,
      required this.color});

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return dateStr;
    }
  }

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
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
            Text(_formatDate(date),
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Day-by-day breakdown list ─────────────────────────────────────────────────

class _DayBreakdownList extends StatelessWidget {
  final List<WeeklyDay> days;
  const _DayBreakdownList({required this.days});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
          const Text('Daily detail',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          ...days.map((day) => _DayRow(day: day, label: _dayLabels[day.weekday])),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final WeeklyDay day;
  final String label;
  const _DayRow({required this.day, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(day.status);
    final pct = (day.adherencePct ?? 0) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
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
                value: day.hasData ? pct.clamp(0.0, 1.0) : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              day.hasData ? '${day.totalCalories.toInt()} kcal' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: day.hasData ? color : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
