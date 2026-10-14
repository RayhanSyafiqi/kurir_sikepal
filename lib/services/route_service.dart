import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/route_model.dart';

class RouteService {
  RouteService._();

  static Future<List<AppRoute>> getAll() async {
    final res = await ApiClient.get(ApiConfig.routes);
    return (res['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(AppRoute.fromJson)
        .toList();
  }
}
