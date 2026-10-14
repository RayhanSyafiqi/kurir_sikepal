class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? image;
  final bool? isActive;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.image,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        image: json['image'] as String?,
        isActive: json['isActive'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'image': image,
        'isActive': isActive,
      };

  String get firstName => name.split(' ').first;
}
