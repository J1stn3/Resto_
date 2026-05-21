class Category {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );
}
