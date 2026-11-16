import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/order_model.dart';

class ReturService {
  ReturService._();

  static Future<List<Order>> getList({int page = 1, int limit = 100}) async {
    final res = await ApiClient.get(
      ApiConfig.retur,
      query: {'page': '$page', 'limit': '$limit'},
    );
    return (res['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();
  }

  static Future<Map<String, dynamic>> process({
    required String orderId,
    required int qty,
    int sisaQuantity = 0, // ✅ Ubah menjadi optional dengan default 0
    String? reason,
  }) async {
    final res = await ApiClient.post(
      ApiConfig.retur,
      body: {
        'orderId': orderId,
        'qty': qty,
        'sisaQuantity': sisaQuantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return res['data'] as Map<String, dynamic>;
  }
}
