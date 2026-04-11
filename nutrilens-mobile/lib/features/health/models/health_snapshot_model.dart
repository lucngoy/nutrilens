class HealthSnapshot {
  final int id;
  final double? weight;
  final double? bmi;
  final double? dailyCalorieTarget;
  final String notes;
  final String source; // 'auto' | 'manual'
  final DateTime recordedAt;

  HealthSnapshot({
    required this.id,
    this.weight,
    this.bmi,
    this.dailyCalorieTarget,
    required this.notes,
    required this.source,
    required this.recordedAt,
  });

  bool get isAuto => source == 'auto';

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) {
    return HealthSnapshot(
      id: json['id'],
      weight: json['weight']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      dailyCalorieTarget: json['daily_calorie_target']?.toDouble(),
      notes: json['notes'] ?? '',
      source: json['source'] ?? 'manual',
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'bmi': bmi,
        'daily_calorie_target': dailyCalorieTarget,
        'notes': notes,
        'source': source,
      };
}
