import 'product_model.dart';

class UserProductModel {
  final int? id;
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final double servingSize;
  final String servingUnit;
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? sugar;
  final double? salt;
  final String status;
  final int confirmationCount;
  final int flagCount;

  UserProductModel({
    this.id,
    required this.barcode,
    required this.name,
    this.brand = '',
    this.imageUrl,
    this.servingSize = 100,
    this.servingUnit = 'g',
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.sugar,
    this.salt,
    this.status = 'pending',
    this.confirmationCount = 0,
    this.flagCount = 0,
  });

  factory UserProductModel.fromJson(Map<String, dynamic> json) {
    return UserProductModel(
      id: json['id'],
      barcode: json['barcode'] ?? '',
      name: json['name'],
      brand: json['brand'] ?? '',
      imageUrl: json['image'],
      servingSize: (json['serving_size'] ?? 100).toDouble(),
      servingUnit: json['serving_unit'] ?? 'g',
      calories: json['calories']?.toDouble(),
      protein: json['protein']?.toDouble(),
      carbohydrates: json['carbohydrates']?.toDouble(),
      fat: json['fat']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      salt: json['salt']?.toDouble(),
      status: json['status'] ?? 'pending',
      confirmationCount: json['confirmation_count'] ?? 0,
      flagCount: json['flag_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'serving_size': servingSize,
    'serving_unit': servingUnit,
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fat': fat,
    'sugar': sugar,
    'salt': salt,
  };

  ProductModel toProductModel({String status = 'pending'}) => ProductModel(
    barcode: barcode,
    name: name,
    brand: brand.isNotEmpty ? brand : null,
    imageUrl: imageUrl,
    source: 'user',
    userProductId: id,
    userProductStatus: status,
    nutrition: NutritionFacts(
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      sugar: sugar,
      salt: salt,
    ),
    allergens: [],
    ingredients: [],
  );
}
