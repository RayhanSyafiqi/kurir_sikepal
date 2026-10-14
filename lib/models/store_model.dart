class Store {
  final String id;
  final String? name;
  final String? grade;
  final String? picName;
  final String? picPhone;
  final String? googleMapsLink;
  final String? category;
  final String? price;
  final String? paymentMethod;
  final String? operationalDays;
  final String? address;
  final String? province;
  final String? city;
  final String? status;
  final String? senderCode;
  final String? notes;

  const Store({
    required this.id,
    this.name,
    this.grade,
    this.picName,
    this.picPhone,
    this.googleMapsLink,
    this.category,
    this.price,
    this.paymentMethod,
    this.operationalDays,
    this.address,
    this.province,
    this.city,
    this.status,
    this.senderCode,
    this.notes,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: _str(json['id']) ?? '',
        name: _str(json['name']),
        grade: _str(json['grade']),
        picName: _str(json['picName']),
        picPhone: _str(json['picPhone']),
        googleMapsLink: _str(json['googleMapsLink']),
        category: _str(json['category']),
        price: _str(json['price']),
        paymentMethod: _str(json['paymentMethod']),
        operationalDays: _str(json['operationalDays']),
        address: _str(json['address']),
        province: _str(json['province']),
        city: _str(json['city']),
        status: _str(json['status']),
        senderCode: _str(json['senderCode']),
        notes: _str(json['notes']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'picName': picName,
        'picPhone': picPhone,
        'googleMapsLink': googleMapsLink,
        'category': category,
        'price': price,
        'paymentMethod': paymentMethod,
        'operationalDays': operationalDays,
        'address': address,
        'province': province,
        'city': city,
        'status': status,
        'senderCode': senderCode,
        'notes': notes,
      };

  bool get isActive => status == 'ACTIVE';

  // ==================== HELPER ====================

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return null;
  }
}
