import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/network/api_client.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.get('/users/insights/');
      setState(() { _data = Map<String, dynamic>.from(resp.data); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Behavioral Insights',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                    Text('Last 28 days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _fetch, child: const Text('Retry')),
                      ]))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final consistencyPct = d['consistency_pct'] as int? ?? 0;
    final streak = d['current_streak'] as int? ?? 0;
    final daysLogged = d['days_logged'] as int? ?? 0;
    final busiestDay = d['busiest_day'] as String? ?? '—';
    final bestDay = d['best_day'] as String? ?? '—';
    final worstDay = d['worst_day'] as String? ?? '—';
    final avgLast7 = (d['avg_calories_last7'] as num?)?.toDouble() ?? 0;
    final avgPrev7 = (d['avg_calories_prev7'] as num?)?.toDouble() ?? 0;
    final trend = d['week_trend'] as String? ?? 'stable';
    final target = (d['calorie_target'] as num?)?.toDouble() ?? 2000;
    final topFoods = (d['top_foods'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e)).toList();
    final mealDist = Map<String, dynamic>.from(d['meal_distribution'] ?? {});
    final avgByWd = (d['avg_by_weekday'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e)).toList();

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Consistency row
          Row(children: [
            Expanded(child: _StatCard(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF27AE60),
              label: 'Consistency',
              value: '$consistencyPct%',
              sub: '$daysLogged / 28 days logged',
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.local_fire_department_outlined,
              iconColor: primaryColor,
              label: 'Current streak',
              value: '$streak ${streak == 1 ? 'day' : 'days'}',
              sub: 'consecutive days',
            )),
          ]),
          const SizedBox(height: 12),

          // Week trend
          _TrendCard(avgLast7: avgLast7, avgPrev7: avgPrev7, trend: trend, target: target),
          const SizedBox(height: 12),

          // Best / busiest / worst day
          _Card(
            icon: Icons.calendar_today_outlined,
            title: 'Day of the week',
            child: Column(children: [
              _DayRow(label: 'Best day', day: bestDay, color: const Color(0xFF27AE60),
                  icon: Icons.thumb_up_outlined),
              const Divider(height: 20),
              _DayRow(label: 'Busiest day', day: busiestDay, color: primaryColor,
                  icon: Icons.local_fire_department_outlined),
              const Divider(height: 20),
              _DayRow(label: 'Hardest day', day: worstDay, color: const Color(0xFFE74C3C),
                  icon: Icons.thumb_down_outlined),
            ]),
          ),
          const SizedBox(height: 12),

          // Avg calories by weekday bar chart
          if (avgByWd.isNotEmpty) ...[
            _Card(
              icon: Icons.bar_chart_outlined,
              title: 'Avg calories by day of week',
              child: SizedBox(
                height: 160,
                child: _WeekdayChart(avgByWd: avgByWd, target: target),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Meal distribution
          if (mealDist.isNotEmpty) ...[
            _Card(
              icon: Icons.restaurant_outlined,
              title: 'Meal distribution',
              child: Column(
                children: mealDist.entries.map((e) {
                  final total = mealDist.values.fold<int>(0, (s, v) => s + (v as int));
                  final pct = total > 0 ? (e.value as int) / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(_mealLabel(e.key),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                          const Spacer(),
                          Text('${e.value}x',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A))),
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _mealColor(e.key)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Top foods
          if (topFoods.isNotEmpty)
            _Card(
              icon: Icons.star_outline_rounded,
              title: 'Most logged foods',
              child: Column(
                children: topFoods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final food = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w700, color: primaryColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(food['name'] ?? '',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)))),
                      Text('${food['count']}x',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snack': return 'Snack';
      default: return type;
    }
  }

  Color _mealColor(String type) {
    switch (type) {
      case 'breakfast': return const Color(0xFFF39C12);
      case 'lunch': return const Color(0xFF27AE60);
      case 'dinner': return const Color(0xFF2980B9);
      default: return Colors.grey;
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Card({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: const Color(0xFFEC6F2D)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Colors.black54)),
        ]),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  const _StatCard({required this.icon, required this.iconColor,
      required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22,
            fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    ),
  );
}

class _TrendCard extends StatelessWidget {
  final double avgLast7;
  final double avgPrev7;
  final String trend;
  final double target;
  const _TrendCard({required this.avgLast7, required this.avgPrev7,
      required this.trend, required this.target});

  @override
  Widget build(BuildContext context) {
    final Color trendColor;
    final IconData trendIcon;
    final String trendLabel;
    switch (trend) {
      case 'up':
        trendColor = const Color(0xFFE74C3C);
        trendIcon = Icons.trending_up_rounded;
        trendLabel = 'More calories than last week';
        break;
      case 'down':
        trendColor = const Color(0xFF27AE60);
        trendIcon = Icons.trending_down_rounded;
        trendLabel = 'Fewer calories than last week';
        break;
      default:
        trendColor = const Color(0xFF2980B9);
        trendIcon = Icons.trending_flat_rounded;
        trendLabel = 'Similar to last week';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(trendIcon, color: trendColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trendLabel, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 3),
            Text('This week: ${avgLast7.toStringAsFixed(0)} kcal/day  •  Last week: ${avgPrev7.toStringAsFixed(0)} kcal/day',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )),
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final String day;
  final Color color;
  final IconData icon;
  const _DayRow({required this.label, required this.day,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(day, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: color)),
    ),
  ]);
}

class _WeekdayChart extends StatelessWidget {
  final List<Map<String, dynamic>> avgByWd;
  final double target;
  const _WeekdayChart({required this.avgByWd, required this.target});

  @override
  Widget build(BuildContext context) {
    final maxY = (avgByWd.map((e) => (e['calories'] as num).toDouble())
        .fold(target, (a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, _) {
              const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Text(labels[val.toInt()],
                  style: const TextStyle(fontSize: 11, color: Colors.grey));
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: target,
          color: const Color(0xFFEC6F2D).withOpacity(0.4),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ]),
      barGroups: List.generate(7, (i) {
        final cal = i < avgByWd.length
            ? (avgByWd[i]['calories'] as num).toDouble()
            : 0.0;
        final color = cal >= target * 0.9 && cal <= target * 1.1
            ? const Color(0xFF27AE60)
            : cal > target * 1.1
                ? const Color(0xFFE74C3C)
                : const Color(0xFF2980B9);
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: cal,
            color: cal > 0 ? color : Colors.grey.shade200,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ]);
      }),
    ));
  }
}
