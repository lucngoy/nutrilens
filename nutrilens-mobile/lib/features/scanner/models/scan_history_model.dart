class ScanHistoryItem {
  final int id;
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? nutriscore;
  final double? calories;
  final DateTime scannedAt;

  ScanHistoryItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.nutriscore,
    this.calories,
    required this.scannedAt,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      brand: json['brand'] ?? '',
      imageUrl: json['image_url']?.isEmpty == true ? null : json['image_url'],
      nutriscore: json['nutriscore']?.isEmpty == true ? null : json['nutriscore'],
      calories: json['calories']?.toDouble(),
      scannedAt: DateTime.parse(json['scanned_at']),
    );
  }
}