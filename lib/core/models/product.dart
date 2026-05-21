class Product {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? sku;
  final bool isAvailable;
  final int preparationTime;
  final String? categoryName;
  final String? categoryColor;

  const Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.sku,
    this.isAvailable = true,
    this.preparationTime = 0,
    this.categoryName,
    this.categoryColor,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        categoryId: json['category_id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.parse(json['price'].toString()),
        imageUrl: json['image_url'] as String?,
        sku: json['sku'] as String?,
        isAvailable: json['is_available'] == true || json['is_available'] == 1,
        preparationTime: json['preparation_time'] as int? ?? 0,
        categoryName: json['category_name'] as String?,
        categoryColor: json['category_color'] as String?,
      );
}
