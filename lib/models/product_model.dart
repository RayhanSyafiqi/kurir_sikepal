class Product {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );
}
