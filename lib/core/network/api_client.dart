import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();

  static const _timeout = Duration(seconds: 20);

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) =>
      _send('GET', path, query: query);

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send('POST', path, body: body);

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send('PATCH', path, body: body);

  static Future<Map<String, dynamic>> delete(String path) =>
      _send('DELETE', path);

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await TokenStorage.get();
    final uri =
        Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw ApiException(0, 'Method tidak didukung');
      }
    } catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server');
    }

    // ============ Parsing response ============
    final statusOk = response.statusCode >= 200 && response.statusCode < 300;

    dynamic decoded;
    if (response.body.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        // Response bukan JSON (kemungkinan HTML error page)
        throw ApiException(
          response.statusCode,
          'Response server bukan JSON (${response.statusCode})',
        );
      }
    }

    // Response sukses: WAJIB Map
    if (statusOk) {
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      // Response 2xx tapi bukan Map → server balikin array/string
      // Kita bungkus jadi {data: <apapun>} supaya konsisten
      return <String, dynamic>{
        'success': true,
        'data': decoded,
      };
    }

    // Response error
    String errorMsg = 'Terjadi kesalahan (${response.statusCode})';
    if (decoded is Map && decoded['error'] != null) {
      errorMsg = decoded['error'].toString();
    } else if (decoded is Map && decoded['message'] != null) {
      errorMsg = decoded['message'].toString();
    }

    throw ApiException(response.statusCode, errorMsg);
  }
}
