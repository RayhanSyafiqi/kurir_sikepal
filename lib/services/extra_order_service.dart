import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/extra_order_model.dart';

class ExtraOrderService {
  ExtraOrderService._();

  static Map<String, dynamic> _asMap(dynamic data, {String? context}) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception(
      'Format data tidak valid${context != null ? ' ($context)' : ''}: '
      'expected Map, got ${data.runtimeType}',
    );
  }

  static List<Map<String, dynamic>> _asListMap(dynamic data,
      {String? context}) {
    if (data is List) {
      return data
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw Exception(
      'Format data tidak valid${context != null ? ' ($context)' : ''}: '
      'expected List, got ${data.runtimeType}',
    );
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // GET LIST
  static Future<List<ExtraOrder>> getAll({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await ApiClient.get(
      ApiConfig.extraOrders,
      query: {
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': _dateStr(startDate),
        if (endDate != null) 'endDate': _dateStr(endDate),
      },
    );
    final list = _asListMap(res['data'], context: 'extra orders list');
    return list.map(ExtraOrder.fromJson).toList();
  }

  // GET DETAIL
  static Future<ExtraOrder> getDetail(String id) async {
    final res = await ApiClient.get(ApiConfig.extraOrderDetail(id));
    final map = _asMap(res['data'], context: 'extra order detail');
    return ExtraOrder.fromJson(map);
  }

  // CREATE
  static Future<ExtraOrder> create({
    required String customerName,
    String? customerPhone,
    String? address,
    String? note,
    required List<Map<String, dynamic>> items,
    DateTime? date,
  }) async {
    final res = await ApiClient.post(
      ApiConfig.extraOrders,
      body: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'note': note,
        'date': date?.toIso8601String().split('T').first,
        'items': items,
      },
    );
    final map = _asMap(res['data'], context: 'create extra order');
    return ExtraOrder.fromJson(map);
  }

  // UPDATE PAYMENT
  static Future<Map<String, dynamic>> updatePayment(
    String id, {
    String? paymentStatus,
    String? paymentMethod,
    String? paymentProof,
  }) async {
    final res = await ApiClient.patch(
      ApiConfig.extraOrderPayment(id),
      body: {
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentProof != null) 'paymentProof': paymentProof,
      },
    );
    return _asMap(res['data'], context: 'extra payment');
  }

  // UPDATE DELIVERY
  static Future<Map<String, dynamic>> updateDelivery(
    String id, {
    String? status,
    String? deliveryProof,
    String? note,
  }) async {
    final res = await ApiClient.patch(
      ApiConfig.extraOrderDelivery(id),
      body: {
        if (status != null) 'status': status,
        if (deliveryProof != null) 'deliveryProof': deliveryProof,
        if (note != null) 'note': note,
      },
    );
    return _asMap(res['data'], context: 'extra delivery');
  }
}
