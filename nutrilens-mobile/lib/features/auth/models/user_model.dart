class UserProfile {
  final int id;
  final DateTime? dateOfBirth;
  final double? weight;
  final double? height;
  final String goal;
  final bool isDiabetic;
  final bool hasHypertension;
  final bool isCeliac;
  final String allergies;
  final double? bmi;

  UserProfile({
    required this.id,
    this.dateOfBirth,
    this.weight,
    this.height,
    required this.goal,
    required this.isDiabetic,
    required this.hasHypertension,
    required this.isCeliac,
    required this.allergies,
    this.bmi,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      goal: json['goal'],
      isDiabetic: json['is_diabetic'],
      hasHypertension: json['has_hypertension'],
      isCeliac: json['is_celiac'],
      allergies: json['allergies'],
      bmi: json['bmi']?.toDouble(),
    );
  }
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final UserProfile profile;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profile: UserProfile.fromJson(json['profile']),
    );
  }
}