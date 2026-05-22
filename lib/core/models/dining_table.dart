class DiningTable {
  final String id;
  final String tableNumber;
  final String? tableName;
  final int seatingCapacity;
  final String? location;
  final bool isOccupied;
  final String? currentOrderId;
  final String? orderNumber;
  final String? orderStatus;
  final String? customerName;

  const DiningTable({
    required this.id,
    required this.tableNumber,
    this.tableName,
    this.seatingCapacity = 4,
    this.location,
    this.isOccupied = false,
    this.currentOrderId,
    this.orderNumber,
    this.orderStatus,
    this.customerName,
  });

  /// Friendly label shown in UI (falls back to table number).
  String get displayName {
    final name = tableName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Table $tableNumber';
  }

  String get zoneLabel => location?.trim().isNotEmpty == true ? location!.trim() : 'Unassigned';

  bool get isAvailable => !isOccupied;

  /// Seats free for new guests (0 when table is occupied).
  int get seatsAvailable => isOccupied ? 0 : seatingCapacity;

  String get seatsLabel {
    final cap = seatingCapacity;
    if (isOccupied) return '$cap seats · in use';
    return '$cap seat${cap == 1 ? '' : 's'} available';
  }

  String get statusLabel => isOccupied ? 'Occupied' : 'Available';

  factory DiningTable.fromJson(Map<String, dynamic> json) {
    final order = json['current_order'] as Map<String, dynamic>?;
    return DiningTable(
      id: json['id'] as String,
      tableNumber: json['table_number'] as String,
      tableName: json['table_name'] as String?,
      seatingCapacity: json['seating_capacity'] as int? ?? 4,
      location: json['location'] as String?,
      isOccupied: json['is_occupied'] == true || json['is_occupied'] == 1,
      currentOrderId: json['current_order_id'] as String? ??
          json['order_id'] as String? ??
          order?['id'] as String?,
      orderNumber: json['order_number'] as String? ?? order?['order_number'] as String?,
      orderStatus: json['order_status'] as String? ?? order?['status'] as String?,
      customerName: json['customer_name'] as String? ?? order?['customer_name'] as String?,
    );
  }
}
