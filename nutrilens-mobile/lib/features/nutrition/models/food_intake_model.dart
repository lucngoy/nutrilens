class FoodIntake {
  final int id;
  final int? product;
  final String name;
  final String imageUrl;
  final String sourceType;  // scan | manual
  final double quantity;
  final String unit;        // g | ml | unit
  final String unitLabel;   // banana, slice, cup...
  final double calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? salt;
  final String mealType;
  final DateTime consumedAt;
  final int weekday;
  final double confidenceScore;

  const FoodIntake({
    required this.id,
    this.product,
    required this.name,
    required this.imageUrl,
    required this.sourceType,
    required this.quantity,
    required this.unit,
    required this.unitLabel,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.sugar,
    this.salt,
    required this.mealType,
    required this.consumedAt,
    this.weekday = 0,
    this.confidenceScore = 1.0,
  });

  factory FoodIntake.fromJson(Map<String, dynamic> json) {
    return FoodIntake(
      id: json['id'] as int,
      product: json['product'] as int?,
      name: (json['name'] ?? '') as String,
      imageUrl: (json['image_url'] ?? '') as String,
      sourceType: (json['source_type'] ?? 'manual') as String,
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      unit: (json['unit'] ?? 'g') as String,
      unitLabel: (json['unit_label'] ?? '') as String,
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      salt: (json['salt'] as num?)?.toDouble(),
      mealType: (json['meal_type'] ?? 'snack') as String,
      consumedAt: json['consumed_at'] != null
          ? DateTime.parse(json['consumed_at'] as String)
          : DateTime.now(),
      weekday: (json['weekday'] as int? ?? 0),
      confidenceScore: (json['confidence_score'] as num? ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (product != null) 'product': product,
      'name': name,
      'image_url': imageUrl,
      'source_type': sourceType,
      'quantity': quantity,
      'unit': unit,
      if (unitLabel.isNotEmpty) 'unit_label': unitLabel,
      'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (sugar != null) 'sugar': sugar,
      if (salt != null) 'salt': salt,
      'meal_type': mealType,
      'consumed_at': consumedAt.toIso8601String(),
    };
  }
}

class DailySummary {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSugar;
  final double totalSalt;
  final double? calorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final double? adherencePct;
  final double? proteinAdherencePct;
  final double? carbsAdherencePct;
  final double? fatAdherencePct;
  final double? remainingCalories;
  final String status; // on_track | warning | exceeded
  final int entryCount;

  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSugar,
    required this.totalSalt,
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.adherencePct,
    this.proteinAdherencePct,
    this.carbsAdherencePct,
    this.fatAdherencePct,
    this.remainingCalories,
    this.status = 'on_track',
    required this.entryCount,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: (json['date'] ?? '') as String,
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
      totalProtein: (json['total_protein'] as num? ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] as num? ?? 0).toDouble(),
      totalFat: (json['total_fat'] as num? ?? 0).toDouble(),
      totalSugar: (json['total_sugar'] as num? ?? 0).toDouble(),
      totalSalt: (json['total_salt'] as num? ?? 0).toDouble(),
      calorieTarget: (json['calorie_target'] as num?)?.toDouble(),
      proteinTarget: (json['protein_target'] as num?)?.toDouble(),
      carbsTarget: (json['carbs_target'] as num?)?.toDouble(),
      fatTarget: (json['fat_target'] as num?)?.toDouble(),
      adherencePct: (json['adherence_pct'] as num?)?.toDouble(),
      proteinAdherencePct: (json['protein_adherence_pct'] as num?)?.toDouble(),
      carbsAdherencePct: (json['carbs_adherence_pct'] as num?)?.toDouble(),
      fatAdherencePct: (json['fat_adherence_pct'] as num?)?.toDouble(),
      remainingCalories: (json['remaining_calories'] as num?)?.toDouble(),
      status: (json['status'] as String? ?? 'on_track'),
      entryCount: (json['entry_count'] as int? ?? 0),
    );
  }
}
