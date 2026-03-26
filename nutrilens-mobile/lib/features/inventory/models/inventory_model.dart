class InventoryItem {
  final int id;
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? nutriscore;
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugar;
  final double? fiber;
  final double? protein;
  final double? salt;
  final int quantity;
  final String unit;
  final int lowStockThreshold;
  final bool isLowStock;
  final String category;
  final String storageLocation;
  final DateTime? expirationDate;
  final String notes;
  final String inventoryType;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.nutriscore,
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugar,
    this.fiber,
    this.protein,
    this.salt,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    required this.isLowStock,
    this.category = '',
    this.storageLocation = '',
    this.expirationDate,
    this.notes = '',
    this.inventoryType = 'personal',
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      brand: json['brand'] ?? '',
      imageUrl: json['image_url']?.isEmpty == true ? null : json['image_url'],
      nutriscore: json['nutriscore']?.isEmpty == true ? null : json['nutriscore'],
      calories: json['calories']?.toDouble(),
      fat: json['fat']?.toDouble(),
      saturatedFat: json['saturated_fat']?.toDouble(),
      carbohydrates: json['carbohydrates']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      fiber: json['fiber']?.toDouble(),
      protein: json['protein']?.toDouble(),
      salt: json['salt']?.toDouble(),
      quantity: json['quantity'],
      unit: json['unit'],
      lowStockThreshold: json['low_stock_threshold'],
      isLowStock: json['is_low_stock'],
      category: json['category'] ?? '',
      storageLocation: json['storage_location'] ?? '',
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      notes: json['notes'] ?? '',
      inventoryType: json['inventory_type'] ?? 'personal',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'image_url': imageUrl ?? '',
      'nutriscore': nutriscore ?? '',
      'calories': calories,
      'fat': fat,
      'saturated_fat': saturatedFat,
      'carbohydrates': carbohydrates,
      'sugar': sugar,
      'fiber': fiber,
      'protein': protein,
      'salt': salt,
      'inventory_type': inventoryType,
    };
  }
}