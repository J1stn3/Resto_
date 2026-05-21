class DiningTable {
  final String id;
  final String tableNumber;
  final int seatingCapacity;
  final String? location;
  final bool isOccupied;
  final String? currentOrderId;
  final String? orderNumber;
  final String? orderStatus;

  const DiningTable({
    required this.id,
    required this.tableNumber,
    this.seatingCapacity = 4,
    this.location,
    this.isOccupied = false,
    this.currentOrderId,
    this.orderNumber,
    this.orderStatus,
  });

  factory DiningTable.fromJson(Map<String, dynamic> json) => DiningTable(
        id: json['id'] as String,
        tableNumber: json['table_number'] as String,
        seatingCapacity: json['seating_capacity'] as int? ?? 4,
        location: json['location'] as String?,
        isOccupied: json['is_occupied'] == true || json['is_occupied'] == 1,
        currentOrderId: json['current_order_id'] as String? ?? json['order_id'] as String?,
        orderNumber: json['order_number'] as String?,
        orderStatus: json['order_status'] as String?,
      );
}
