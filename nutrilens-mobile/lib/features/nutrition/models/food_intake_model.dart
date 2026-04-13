class FoodIntake {
  final int id;
  final int? product;
  final String name;
  final String imageUrl;
  final double quantity;
  final String unit;
  final double calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? salt;
  final String mealType;
  final DateTime consumedAt;

  const FoodIntake({
    required this.id,
    this.product,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.unit,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.sugar,
    this.salt,
    required this.mealType,
    required this.consumedAt,
  });

  factory FoodIntake.fromJson(Map<String, dynamic> json) {
    return FoodIntake(
      id: json['id'] as int,
      product: json['product'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'g',
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      salt: (json['salt'] as num?)?.toDouble(),
      mealType: json['meal_type'] as String? ?? 'snack',
      consumedAt: DateTime.parse(json['consumed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (product != null) 'product': product,
      'name': name,
      'image_url': imageUrl,
      'quantity': quantity,
      'unit': unit,
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
    required this.entryCount,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'] as String,
      totalCalories: (json['total_calories'] as num).toDouble(),
      totalProtein: (json['total_protein'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      totalFat: (json['total_fat'] as num).toDouble(),
      totalSugar: (json['total_sugar'] as num).toDouble(),
      totalSalt: (json['total_salt'] as num).toDouble(),
      calorieTarget: (json['calorie_target'] as num?)?.toDouble(),
      proteinTarget: (json['protein_target'] as num?)?.toDouble(),
      carbsTarget: (json['carbs_target'] as num?)?.toDouble(),
      fatTarget: (json['fat_target'] as num?)?.toDouble(),
      adherencePct: (json['adherence_pct'] as num?)?.toDouble(),
      entryCount: json['entry_count'] as int,
    );
  }
}
