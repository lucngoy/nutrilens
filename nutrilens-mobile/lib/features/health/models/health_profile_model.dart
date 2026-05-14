class HealthProfile {
  final String? gender;
  final DateTime? dateOfBirth;
  final int? age;
  final double? weight;
  final double? height;
  final String goal;
  final String activityLevel;
  final String activityFrequency;
  final String activityIntensity;
  final String activityDuration;
  final List<String> activityTypes;
  final String lifestyle;
  final bool medicalConsentAccepted;
  final double? activityScore;
  final double? activityMultiplier;
  final bool isDiabetic;
  final bool hasHypertension;
  final bool isCeliac;
  final bool isLactoseIntolerant;
  final bool isVegan;
  final bool isVegetarian;
  final bool isFlexitarian;
  final String diabetesType;
  final String lactoseIntoleranceLevel;
  final String allergies;
  final String? avatar;
  final double? dailyCalories;
  final double? dailyProtein;
  final double? dailyCarbs;
  final double? dailyFat;
  final double? dailySugarLimit;
  final double? dailySaltLimit;
  final double? bmi;
  final double? dailyCalorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final double? sugarLimitTarget;
  final double? saltLimitTarget;

  HealthProfile({
    this.gender,
    this.dateOfBirth,
    this.age,
    this.weight,
    this.height,
    required this.goal,
    required this.activityLevel,
    this.activityFrequency = '',
    this.activityIntensity = '',
    this.activityDuration = '',
    this.activityTypes = const [],
    this.lifestyle = 'desk',
    this.medicalConsentAccepted = false,
    this.activityScore,
    this.activityMultiplier,
    required this.isDiabetic,
    required this.hasHypertension,
    required this.isCeliac,
    required this.isLactoseIntolerant,
    required this.isVegan,
    required this.isVegetarian,
    required this.isFlexitarian,
    this.diabetesType = '',
    this.lactoseIntoleranceLevel = '',
    required this.allergies,
    this.avatar,
    this.dailyCalories,
    this.dailyProtein,
    this.dailyCarbs,
    this.dailyFat,
    this.dailySugarLimit,
    this.dailySaltLimit,
    this.bmi,
    this.dailyCalorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.sugarLimitTarget,
    this.saltLimitTarget,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      gender: json['gender']?.isEmpty == true ? null : json['gender'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      age: json['age'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      goal: json['goal'] ?? 'eat_healthy',
      activityLevel: json['activity_level'] ?? 'moderate',
      activityFrequency: json['activity_frequency'] ?? '',
      activityIntensity: json['activity_intensity'] ?? '',
      activityDuration: json['activity_duration'] ?? '',
      activityTypes: json['activity_types'] != null && (json['activity_types'] as String).isNotEmpty
          ? (json['activity_types'] as String).split(',').map((s) => s.trim()).toList()
          : [],
      lifestyle: json['lifestyle'] ?? 'desk',
      medicalConsentAccepted: json['medical_consent_accepted'] ?? false,
      activityScore: json['activity_score']?.toDouble(),
      activityMultiplier: json['activity_multiplier']?.toDouble(),
      isDiabetic: json['is_diabetic'] ?? false,
      hasHypertension: json['has_hypertension'] ?? false,
      isCeliac: json['is_celiac'] ?? false,
      isLactoseIntolerant: json['is_lactose_intolerant'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isVegetarian: json['is_vegetarian'] ?? false,
      isFlexitarian: json['is_flexitarian'] ?? false,
      diabetesType: json['diabetes_type'] ?? '',
      lactoseIntoleranceLevel: json['lactose_intolerance_level'] ?? '',
      allergies: json['allergies'] ?? '',
      avatar: json['avatar'],
      dailyCalories: json['daily_calories']?.toDouble(),
      dailyProtein: json['daily_protein']?.toDouble(),
      dailyCarbs: json['daily_carbs']?.toDouble(),
      dailyFat: json['daily_fat']?.toDouble(),
      dailySugarLimit: json['daily_sugar_limit']?.toDouble(),
      dailySaltLimit: json['daily_salt_limit']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      dailyCalorieTarget: json['daily_calorie_target']?.toDouble(),
      proteinTarget: json['protein_target']?.toDouble(),
      carbsTarget: json['carbs_target']?.toDouble(),
      fatTarget: json['fat_target']?.toDouble(),
      sugarLimitTarget: json['sugar_limit_target']?.toDouble(),
      saltLimitTarget: json['salt_limit_target']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender ?? '',
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'weight': weight,
      'height': height,
      'goal': goal,
      'activity_level': activityLevel,
      'activity_frequency': activityFrequency,
      'activity_intensity': activityIntensity,
      'activity_duration': activityDuration,
      'activity_types': activityTypes.join(','),
      'lifestyle': lifestyle,
      'is_diabetic': isDiabetic,
      'has_hypertension': hasHypertension,
      'is_celiac': isCeliac,
      'is_lactose_intolerant': isLactoseIntolerant,
      'is_vegan': isVegan,
      'is_vegetarian': isVegetarian,
      'is_flexitarian': isFlexitarian,
      'diabetes_type': diabetesType,
      'lactose_intolerance_level': lactoseIntoleranceLevel,
      'allergies': allergies,
      'daily_calories': dailyCalories,
      'daily_protein': dailyProtein,
      'daily_carbs': dailyCarbs,
      'daily_fat': dailyFat,
      'daily_sugar_limit': dailySugarLimit,
      'daily_salt_limit': dailySaltLimit,
    };
  }

  HealthProfile copyWith({
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    String? goal,
    String? activityLevel,
    String? activityFrequency,
    String? activityIntensity,
    String? activityDuration,
    List<String>? activityTypes,
    String? lifestyle,
    bool? isDiabetic,
    bool? hasHypertension,
    bool? isCeliac,
    bool? isLactoseIntolerant,
    bool? isVegan,
    bool? isVegetarian,
    bool? isFlexitarian,
    String? diabetesType,
    String? lactoseIntoleranceLevel,
    String? allergies,
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
    double? dailySugarLimit,
    double? dailySaltLimit,
  }) {
    return HealthProfile(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      activityFrequency: activityFrequency ?? this.activityFrequency,
      activityIntensity: activityIntensity ?? this.activityIntensity,
      activityDuration: activityDuration ?? this.activityDuration,
      activityTypes: activityTypes ?? this.activityTypes,
      lifestyle: lifestyle ?? this.lifestyle,
      isDiabetic: isDiabetic ?? this.isDiabetic,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      isCeliac: isCeliac ?? this.isCeliac,
      isLactoseIntolerant: isLactoseIntolerant ?? this.isLactoseIntolerant,
      isVegan: isVegan ?? this.isVegan,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isFlexitarian: isFlexitarian ?? this.isFlexitarian,
      diabetesType: diabetesType ?? this.diabetesType,
      lactoseIntoleranceLevel: lactoseIntoleranceLevel ?? this.lactoseIntoleranceLevel,
      allergies: allergies ?? this.allergies,
      avatar: avatar,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
      dailySugarLimit: dailySugarLimit ?? this.dailySugarLimit,
      dailySaltLimit: dailySaltLimit ?? this.dailySaltLimit,
      bmi: bmi,
      dailyCalorieTarget: dailyCalorieTarget,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
      sugarLimitTarget: sugarLimitTarget,
      saltLimitTarget: saltLimitTarget,
    );
  }

  String get bmiCategory {
    if (bmi == null) return 'Unknown';
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Overweight';
    return 'Obese';
  }

  List<String> get conditions {
    final list = <String>[];
    if (isDiabetic) list.add('Diabetic');
    if (hasHypertension) list.add('Hypertension');
    if (isCeliac) list.add('Celiac');
    if (isLactoseIntolerant) list.add('Lactose intolerant');
    if (isVegan) list.add('Vegan');
    if (isVegetarian) list.add('Vegetarian');
    return list;
  }
}