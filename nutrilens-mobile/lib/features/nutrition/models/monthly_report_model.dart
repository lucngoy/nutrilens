class MonthlyWeek {
  final String week;
  final String weekStart;
  final String weekEnd;
  final bool hasData;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double avgCaloriesPerDay;
  final double? calorieTargetWeek;
  final double? calorieTargetDaily;
  final double? adherencePct;
  final String status; // on_track | warning | exceeded | no_data
  final int daysLogged;
  final int daysInWeek;

  const MonthlyWeek({
    required this.week,
    required this.weekStart,
    required this.weekEnd,
    required this.hasData,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.avgCaloriesPerDay,
    this.calorieTargetWeek,
    this.calorieTargetDaily,
    this.adherencePct,
    required this.status,
    required this.daysLogged,
    required this.daysInWeek,
  });

  factory MonthlyWeek.fromJson(Map<String, dynamic> json) {
    return MonthlyWeek(
      week: (json['week'] ?? '') as String,
      weekStart: (json['week_start'] ?? '') as String,
      weekEnd: (json['week_end'] ?? '') as String,
      hasData: (json['has_data'] as bool? ?? false),
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
      totalProtein: (json['total_protein'] as num? ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] as num? ?? 0).toDouble(),
      totalFat: (json['total_fat'] as num? ?? 0).toDouble(),
      avgCaloriesPerDay: (json['avg_calories_per_day'] as num? ?? 0).toDouble(),
      calorieTargetWeek: (json['calorie_target_week'] as num?)?.toDouble(),
      calorieTargetDaily: (json['calorie_target_daily'] as num?)?.toDouble(),
      adherencePct: (json['adherence_pct'] as num?)?.toDouble(),
      status: (json['status'] as String? ?? 'no_data'),
      daysLogged: (json['days_logged'] as int? ?? 0),
      daysInWeek: (json['days_in_week'] as int? ?? 7),
    );
  }
}

class MonthlySummary {
  final double avgCalories;
  final double totalCalories;
  final double? calorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final int daysLogged;
  final int daysInMonth;
  final int daysOnTrack;
  final int daysExceeded;
  final String? bestDay;
  final String? worstDay;
  final String trend;
  final String trendLabel;

  const MonthlySummary({
    required this.avgCalories,
    required this.totalCalories,
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    required this.daysLogged,
    required this.daysInMonth,
    required this.daysOnTrack,
    required this.daysExceeded,
    this.bestDay,
    this.worstDay,
    required this.trend,
    required this.trendLabel,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      avgCalories: (json['avg_calories'] as num? ?? 0).toDouble(),
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
      calorieTarget: (json['calorie_target'] as num?)?.toDouble(),
      proteinTarget: (json['protein_target'] as num?)?.toDouble(),
      carbsTarget: (json['carbs_target'] as num?)?.toDouble(),
      fatTarget: (json['fat_target'] as num?)?.toDouble(),
      daysLogged: (json['days_logged'] as int? ?? 0),
      daysInMonth: (json['days_in_month'] as int? ?? 30),
      daysOnTrack: (json['days_on_track'] as int? ?? 0),
      daysExceeded: (json['days_exceeded'] as int? ?? 0),
      bestDay: json['best_day'] as String?,
      worstDay: json['worst_day'] as String?,
      trend: (json['trend'] as String? ?? 'stable'),
      trendLabel: (json['trend_label'] as String? ?? ''),
    );
  }
}

class MonthlyReport {
  final String month;
  final String monthName;
  final String monthStart;
  final String monthEnd;
  final List<MonthlyWeek> weeks;
  final MonthlySummary summary;

  const MonthlyReport({
    required this.month,
    required this.monthName,
    required this.monthStart,
    required this.monthEnd,
    required this.weeks,
    required this.summary,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month: (json['month'] ?? '') as String,
      monthName: (json['month_name'] ?? '') as String,
      monthStart: (json['month_start'] ?? '') as String,
      monthEnd: (json['month_end'] ?? '') as String,
      weeks: (json['weeks'] as List<dynamic>? ?? [])
          .map((w) => MonthlyWeek.fromJson(w as Map<String, dynamic>))
          .toList(),
      summary: MonthlySummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}
