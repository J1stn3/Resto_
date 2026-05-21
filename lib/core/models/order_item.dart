import 'product.dart';

class OrderItem {
  final String id;
  final String productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? specialInstructions;
  final String status;

  const OrderItem({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.specialInstructions,
    this.status = 'pending',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toDouble() : double.parse(json['unit_price'].toString()),
        totalPrice: (json['total_price'] is num) ? (json['total_price'] as num).toDouble() : double.parse(json['total_price'].toString()),
        specialInstructions: json['special_instructions'] as String?,
        status: json['status'] as String? ?? 'pending',
      );
}

class CartItem {
  final ProductRef product;
  int quantity;
  String? specialInstructions;

  CartItem({required this.product, this.quantity = 1, this.specialInstructions});

  double get lineTotal => product.price * quantity;
}

class ProductRef {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? sku;
  final String? categoryName;

  ProductRef({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.sku,
    this.categoryName,
  });
}

extension ProductToRef on Product {
  ProductRef get ref => ProductRef(
        id: id,
        name: name,
        price: price,
        imageUrl: imageUrl,
        sku: sku,
        categoryName: categoryName,
      );
}
