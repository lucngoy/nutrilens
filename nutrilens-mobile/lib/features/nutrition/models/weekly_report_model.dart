class WeeklyDay {
  final String date;
  final int weekday; // 0=Mon … 6=Sun
  final bool hasData;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double? calorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final double? adherencePct;
  final String status; // on_track | warning | exceeded | no_data
  final int entryCount;

  const WeeklyDay({
    required this.date,
    required this.weekday,
    required this.hasData,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.adherencePct,
    required this.status,
    required this.entryCount,
  });

  factory WeeklyDay.fromJson(Map<String, dynamic> json) {
    return WeeklyDay(
      date: (json['date'] ?? '') as String,
      weekday: (json['weekday'] as int? ?? 0),
      hasData: (json['has_data'] as bool? ?? false),
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
      totalProtein: (json['total_protein'] as num? ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] as num? ?? 0).toDouble(),
      totalFat: (json['total_fat'] as num? ?? 0).toDouble(),
      calorieTarget: (json['calorie_target'] as num?)?.toDouble(),
      proteinTarget: (json['protein_target'] as num?)?.toDouble(),
      carbsTarget: (json['carbs_target'] as num?)?.toDouble(),
      fatTarget: (json['fat_target'] as num?)?.toDouble(),
      adherencePct: (json['adherence_pct'] as num?)?.toDouble(),
      status: (json['status'] as String? ?? 'no_data'),
      entryCount: (json['entry_count'] as int? ?? 0),
    );
  }
}

class WeeklySummary {
  final double avgCalories;
  final double avgProtein;
  final double? calorieTarget;
  final String? bestDay;
  final String? worstDay;
  final int daysOnTrack;
  final int daysWarning;
  final int daysExceeded;
  final int daysNoData;
  final String trend; // up | down | stable
  final String trendLabel;

  const WeeklySummary({
    required this.avgCalories,
    required this.avgProtein,
    this.calorieTarget,
    this.bestDay,
    this.worstDay,
    required this.daysOnTrack,
    required this.daysWarning,
    required this.daysExceeded,
    required this.daysNoData,
    required this.trend,
    required this.trendLabel,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      avgCalories: (json['avg_calories'] as num? ?? 0).toDouble(),
      avgProtein: (json['avg_protein'] as num? ?? 0).toDouble(),
      calorieTarget: (json['calorie_target'] as num?)?.toDouble(),
      bestDay: json['best_day'] as String?,
      worstDay: json['worst_day'] as String?,
      daysOnTrack: (json['days_on_track'] as int? ?? 0),
      daysWarning: (json['days_warning'] as int? ?? 0),
      daysExceeded: (json['days_exceeded'] as int? ?? 0),
      daysNoData: (json['days_no_data'] as int? ?? 0),
      trend: (json['trend'] as String? ?? 'stable'),
      trendLabel: (json['trend_label'] as String? ?? ''),
    );
  }
}

class WeeklyReport {
  final String week;
  final String weekStart;
  final String weekEnd;
  final List<WeeklyDay> days;
  final WeeklySummary summary;

  const WeeklyReport({
    required this.week,
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.summary,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      week: (json['week'] ?? '') as String,
      weekStart: (json['week_start'] ?? '') as String,
      weekEnd: (json['week_end'] ?? '') as String,
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => WeeklyDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      summary: WeeklySummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}
