class AppRoute {
  final String id;
  final String name;
  final String? description;
  final int? orderCount;

  const AppRoute({
    required this.id,
    required this.name,
    this.description,
    this.orderCount,
  });

  factory AppRoute.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return AppRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      orderCount: count?['orders'] as int?,
    );
  }
}
