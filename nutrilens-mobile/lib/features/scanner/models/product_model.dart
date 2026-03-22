class ProductModel {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionFacts nutrition;
  final List<String> allergens;
  final List<String> ingredients;
  final String? nutriscore;

  ProductModel({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.nutrition,
    required this.allergens,
    required this.ingredients,
    this.nutriscore,
  });

  factory ProductModel.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};
    final allergensRaw = product['allergens_tags'] as List? ?? [];
    final ingredientsRaw = product['ingredients'] as List? ?? [];

    return ProductModel(
      barcode: product['code'] ?? '',
      name: product['product_name'] ?? 'Unknown product',
      brand: product['brands'],
      imageUrl: product['image_url'],
      nutriscore: product['nutriscore_grade'],
      allergens: allergensRaw
          .map((a) => a.toString().replaceAll('en:', ''))
          .toList(),
      ingredients: ingredientsRaw
          .map((i) => i['text']?.toString() ?? '')
          .where((i) => i.isNotEmpty)
          .toList(),
      nutrition: NutritionFacts(
        calories: _toDouble(nutriments['energy-kcal_100g']),
        fat: _toDouble(nutriments['fat_100g']),
        saturatedFat: _toDouble(nutriments['saturated-fat_100g']),
        carbohydrates: _toDouble(nutriments['carbohydrates_100g']),
        sugar: _toDouble(nutriments['sugars_100g']),
        fiber: _toDouble(nutriments['fiber_100g']),
        protein: _toDouble(nutriments['proteins_100g']),
        salt: _toDouble(nutriments['salt_100g']),
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}

class NutritionFacts {
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugar;
  final double? fiber;
  final double? protein;
  final double? salt;

  NutritionFacts({
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugar,
    this.fiber,
    this.protein,
    this.salt,
  });
}