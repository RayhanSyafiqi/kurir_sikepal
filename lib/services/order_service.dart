import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService._();

  // ==================== HELPERS ====================
  static Map<String, dynamic> _asMap(dynamic data, {String? context}) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception(
      'Format data tidak valid${context != null ? ' ($context)' : ''}: '
      'expected Map, got ${data.runtimeType}',
    );
  }

  static List<Map<String, dynamic>> _asListMap(dynamic data,
      {String? context}) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw Exception(
      'Format data tidak valid${context != null ? ' ($context)' : ''}: '
      'expected List, got ${data.runtimeType}',
    );
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ==================== GET LIST ====================
  static Future<List<Order>> getAll({
    String? storeId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await ApiClient.get(
      ApiConfig.orders,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (storeId != null) 'storeId': storeId,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': _dateStr(startDate),
        if (endDate != null) 'endDate': _dateStr(endDate),
      },
    );
    final list = _asListMap(res['data'], context: 'orders list');
    return list.map(Order.fromJson).toList();
  }

  // ==================== GET DETAIL ====================
  static Future<Order> getDetail(String id) async {
    final res = await ApiClient.get(ApiConfig.orderDetail(id));
    final map = _asMap(res['data'], context: 'order detail');
    return Order.fromJson(map);
  }

  // ==================== CREATE ====================
  static Future<Order> create({
    required String storeId,
    required String routeId,
    required List<Map<String, dynamic>> items,
    DateTime? date,
    String? note,
  }) async {
    final res = await ApiClient.post(
      ApiConfig.orders,
      body: {
        'storeId': storeId,
        'routeId': routeId,
        'date': date?.toIso8601String().split('T').first,
        'note': note,
        'items': items,
      },
    );
    final map = _asMap(res['data'], context: 'create order');
    return Order.fromJson(map);
  }

  // ==================== UPDATE DELIVERY ====================
  static Future<Order> updateDelivery(
    String id, {
    int? shippedQuantity,
    int? remaining,
    String? note,
    String? status,
    String? deliveryProof,
  }) async {
    final res = await ApiClient.patch(
      '${ApiConfig.orderDetail(id)}/delivery',
      body: {
        if (shippedQuantity != null) 'shippedQuantity': shippedQuantity,
        if (remaining != null) 'remaining': remaining,
        if (note != null) 'note': note,
        if (status != null) 'status': status,
        if (deliveryProof != null) 'deliveryProof': deliveryProof,
      },
    );
    final map = _asMap(res['data'], context: 'update delivery');
    return Order.fromJson(map);
  }

  // ==================== UPDATE PAYMENT ====================
  static Future<Map<String, dynamic>> updatePayment(
    String id, {
    String? paymentStatus,
    String? paymentProof,
    String? paymentMethod,
  }) async {
    final res = await ApiClient.patch(
      '${ApiConfig.orderDetail(id)}/payment',
      body: {
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (paymentProof != null) 'paymentProof': paymentProof,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
    );
    return _asMap(res['data'], context: 'update payment');
  }

  // ==================== BULK PAYMENT ====================
  /// Bayar beberapa order sekaligus
  ///
  /// - [orderIds]: list ID order yang mau dibayar
  /// - [paymentMethod]: "CASH" atau "TRANSFER"
  /// - [paymentProof]: base64 string (wajib kalau TRANSFER)
  static Future<Map<String, dynamic>> bulkPayment({
    required List<String> orderIds,
    required String paymentMethod,
    String? paymentProof,
  }) async {
    if (orderIds.isEmpty) {
      throw Exception('Pilih minimal 1 order');
    }
    if (!['CASH', 'TRANSFER'].contains(paymentMethod)) {
      throw Exception('Metode harus CASH atau TRANSFER');
    }
    if (paymentMethod == 'TRANSFER' &&
        (paymentProof == null || paymentProof.isEmpty)) {
      throw Exception('Bukti transfer wajib diisi');
    }

    final res = await ApiClient.post(
      ApiConfig.bulkPayment,
      body: {
        'orderIds': orderIds,
        'paymentMethod': paymentMethod,
        if (paymentProof != null) 'paymentProof': paymentProof,
      },
    );
    return _asMap(res['data'], context: 'bulk payment');
  }

  // ==================== BULK PAYMENT DETAILED ====================
  /// Versi bulk payment dengan return lengkap:
  /// - updatedCount: jumlah order yang berhasil
  /// - totalAmount: total yang dibayar
  /// - paymentMethod
  /// - orders: list order yang diupdate
  static Future<BulkPaymentResult> bulkPaymentDetailed({
    required List<String> orderIds,
    required String paymentMethod,
    String? paymentProof,
  }) async {
    final data = await bulkPayment(
      orderIds: orderIds,
      paymentMethod: paymentMethod,
      paymentProof: paymentProof,
    );

    return BulkPaymentResult(
      updatedCount: (data['updatedCount'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? paymentMethod,
    );
  }
}

// ==================== RESULT CLASS ====================
class BulkPaymentResult {
  final int updatedCount;
  final double totalAmount;
  final String paymentMethod;

  BulkPaymentResult({
    required this.updatedCount,
    required this.totalAmount,
    required this.paymentMethod,
  });
}
