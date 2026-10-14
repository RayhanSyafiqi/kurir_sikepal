import 'dart:convert';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static Future<(User, String)> login(String email, String password) async {
    final res = await ApiClient.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
    );

    final data = res['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await TokenStorage.save(token);
    await TokenStorage.saveUserJson(jsonEncode(user.toJson()));

    return (user, token);
  }

  static Future<User> me() async {
    final res = await ApiClient.get(ApiConfig.me);
    return User.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<void> logout() => TokenStorage.clear();
}
