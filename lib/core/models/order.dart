import 'order_item.dart';

class Order {
  final String id;
  final String orderNumber;
  final String? tableId;
  final String? customerName;
  final String orderType;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  final String? tableNumber;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    this.tableId,
    this.customerName,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.notes,
    this.tableNumber,
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      tableId: json['table_id'] as String?,
      customerName: json['customer_name'] as String?,
      orderType: json['order_type'] as String,
      status: json['status'] as String,
      subtotal: _toDouble(json['subtotal']),
      taxAmount: _toDouble(json['tax_amount']),
      discountAmount: _toDouble(json['discount_amount']),
      totalAmount: _toDouble(json['total_amount']),
      notes: json['notes'] as String?,
      tableNumber: json['table']?['table_number'] as String? ?? json['table_number'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      items: itemsJson.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
}
