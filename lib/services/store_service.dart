import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/store_model.dart';

class StoreService {
  StoreService._();

  static Future<List<Store>> getAll({
    String? search,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    final res = await ApiClient.get(
      ApiConfig.stores,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return (res['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Store.fromJson)
        .toList();
  }

  static Future<Store> getDetail(String id) async {
    final res = await ApiClient.get(ApiConfig.storeDetail(id));
    return Store.fromJson(res['data'] as Map<String, dynamic>);
  }
}
