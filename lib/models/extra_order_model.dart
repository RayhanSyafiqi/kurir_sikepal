class ExtraOrder {
  final String id;
  final DateTime date;
  final String courierId;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? note;
  final int totalQuantity;
  final double price;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentProof;
  final DateTime? paymentProofAt;
  final String? deliveryProof;
  final DateTime? deliveryProofAt;
  final List<ExtraOrderItem> items;

  const ExtraOrder({
    required this.id,
    required this.date,
    required this.courierId,
    this.customerName,
    this.customerPhone,
    this.address,
    this.note,
    required this.totalQuantity,
    required this.price,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentProof,
    this.paymentProofAt,
    this.deliveryProof,
    this.deliveryProofAt,
    this.items = const [],
  });

  factory ExtraOrder.fromJson(Map<String, dynamic> json) {
    return ExtraOrder(
      id: json['id']?.toString() ?? '',
      date: json['date'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      courierId: json['courierId']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      address: json['address']?.toString(),
      note: json['note']?.toString(),
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'DELIVERED',
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      paymentMethod: json['paymentMethod']?.toString(),
      paymentProof: json['paymentProof']?.toString(),
      paymentProofAt: json['paymentProofAt'] == null
          ? null
          : DateTime.tryParse(json['paymentProofAt'].toString()),
      deliveryProof: json['deliveryProof']?.toString(),
      deliveryProofAt: json['deliveryProofAt'] == null
          ? null
          : DateTime.tryParse(json['deliveryProofAt'].toString()),
      items: json['items'] is List
          ? (json['items'] as List)
              .where((e) => e is Map)
              .map((e) => ExtraOrderItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }

  bool get isPaid => paymentStatus == 'PAID' || paymentStatus == 'VERIFIED';
  bool get isEditable => status != 'COMPLETED' && status != 'CANCELLED';
  bool get hasDeliveryProof =>
      deliveryProof != null && deliveryProof!.isNotEmpty;
  bool get hasPaymentProof => paymentProof != null && paymentProof!.isNotEmpty;
}

class ExtraOrderItem {
  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final double price;

  const ExtraOrderItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory ExtraOrderItem.fromJson(Map<String, dynamic> json) {
    return ExtraOrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
