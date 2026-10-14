import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService._();

  static Future<List<Product>> getAll({
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final res = await ApiClient.get(
      ApiConfig.products,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return (res['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}
