import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/api_exception.dart';
import '../../core/logger.dart';
import '../models/product.dart';

/// Thin wrapper over dummyjson.com that maps every failure to [ApiException].
class ApiClient {
  static const _base = 'https://dummyjson.com';
  static const _timeout = Duration(seconds: 15);

  final http.Client _http;
  ApiClient([http.Client? client]) : _http = client ?? http.Client();

  Future<String> login(String username, String password) async {
    final json = await _send(
      'POST',
      '$_base/auth/login',
      () => _http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
    final token = json['accessToken'] as String?;
    if (token == null) throw const ApiException('Unexpected server response.');
    return token;
  }

  Future<ProductPage> getProducts({
    required int skip,
    required int limit,
    String? token,
  }) async {
    final url = '$_base/products?limit=$limit&skip=$skip';
    final json = await _send(
      'GET',
      url,
      () => _http.get(
        Uri.parse(url),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
    final items = (json['products'] as List<dynamic>)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProductPage(items, json['total'] as int? ?? items.length);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String url,
    Future<http.Response> Function() call,
  ) async {
    final watch = Stopwatch()..start();
    logd('API', '--> $method $url');
    try {
      final res = await call().timeout(_timeout);
      logd(
        'API',
        '<-- ${res.statusCode} $method $url (${watch.elapsedMilliseconds}ms, ${res.bodyBytes.length}B)',
      );
      final body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body as Map<String, dynamic>;
      }
      final msg = body is Map ? body['message'] as String? : null;
      throw ApiException(msg ?? 'Request failed (${res.statusCode}).');
    } on ApiException catch (e) {
      logd('API', 'xxx $method $url -> ${e.message}');
      rethrow;
    } on TimeoutException {
      logd('API', 'xxx $method $url -> timeout after ${_timeout.inSeconds}s');
      throw const ApiException('The request timed out. Please try again.');
    } on SocketException catch (e) {
      logd('API', 'xxx $method $url -> $e');
      throw const ApiException('No internet connection.');
    } on http.ClientException catch (e) {
      logd('API', 'xxx $method $url -> $e');
      throw const ApiException('No internet connection.');
    } on FormatException catch (e) {
      logd('API', 'xxx $method $url -> bad JSON: $e');
      throw const ApiException('Unexpected server response.');
    }
  }
}
