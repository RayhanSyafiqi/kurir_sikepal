import 'store_model.dart';

class Order {
  final String id;
  final DateTime date;
  final String status;
  final String courierId;
  final int totalQuantity;
  final int shippedQuantity;
  final double price;
  final double totalAmount;
  final int remaining;
  final String? note;
  final String paymentStatus;
  final String? paymentProof;
  final String? paymentMethod;
  final DateTime? paymentProofAt;
  final String? deliveryProof;
  final DateTime? deliveryProofAt;
  final Store? store;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.courierId,
    required this.totalQuantity,
    required this.shippedQuantity,
    required this.price,
    required this.totalAmount,
    required this.remaining,
    this.note,
    required this.paymentStatus,
    this.paymentProof,
    this.paymentMethod,
    this.paymentProofAt,
    this.deliveryProof,
    this.deliveryProofAt,
    this.store,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: _str(json['id']),
      date: _date(json['date']),
      status: _str(json['status'], 'DELIVERED'),
      courierId: _str(json['courierId']),
      totalQuantity: _int(json['totalQuantity']),
      shippedQuantity: _int(json['shippedQuantity']),
      price: _double(json['price']),
      totalAmount: _double(json['totalAmount']),
      remaining: _int(json['remaining']),
      note: json['note'] == null ? null : _str(json['note']),
      paymentStatus: _str(json['paymentStatus'], 'UNPAID'),
      paymentProof:
          json['paymentProof'] == null ? null : _str(json['paymentProof']),
      paymentMethod:
          json['paymentMethod'] == null ? null : _str(json['paymentMethod']),
      paymentProofAt:
          json['paymentProofAt'] == null ? null : _date(json['paymentProofAt']),
      deliveryProof:
          json['deliveryProof'] == null ? null : _str(json['deliveryProof']),
      deliveryProofAt: json['deliveryProofAt'] == null
          ? null
          : _date(json['deliveryProofAt']),
      store: _parseStore(json['store']),
      items: _parseItems(json['items']),
    );
  }

  bool get isPaid => paymentStatus == 'PAID' || paymentStatus == 'VERIFIED';
  bool get isEditable => status != 'COMPLETED' && status != 'CANCELLED';
  bool get hasDeliveryProof =>
      deliveryProof != null && deliveryProof!.isNotEmpty;
  bool get hasPaymentProof => paymentProof != null && paymentProof!.isNotEmpty;

  // ============ HELPERS ============
  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _double(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static DateTime _date(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  static Store? _parseStore(dynamic v) {
    if (v == null) return null;
    if (v is Map) return Store.fromJson(Map<String, dynamic>.from(v));
    return null;
  }

  static List<OrderItem> _parseItems(dynamic v) {
    if (v == null || v is! List) return const [];
    return v
        .whereType<Map>()
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class OrderItem {
  final String id;
  final int quantity;
  final String? productId;
  final String? productName;

  const OrderItem({
    required this.id,
    required this.quantity,
    this.productId,
    this.productName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? product;
    final p = json['product'];
    if (p is Map) product = Map<String, dynamic>.from(p);
    return OrderItem(
      id: json['id']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
      productId: product?['id']?.toString(),
      productName: product?['name']?.toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
