class User {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = true,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Administrator',
        email: json['email'] as String? ?? '',
        isAdmin: json['is_admin'] == true || json['is_admin'] == 1 || json['is_admin'] == null,
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_admin': isAdmin,
        'is_active': isActive,
      };
}
