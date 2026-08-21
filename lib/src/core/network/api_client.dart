import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? client, TokenStore? tokenStore})
      : _client = client ?? http.Client(),
        _tokenStore = tokenStore ?? TokenStore();

  final http.Client _client;
  final TokenStore _tokenStore;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool requiresAuth = false,
  }) {
    return _request('GET', path, query: query, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return _request('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool allowRefresh = true,
  }) async {
    final accessToken = requiresAuth ? await _tokenStore.readAccessToken() : null;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final uri = ApiConfig.endpoint(path, query);
    final response = method == 'GET'
        ? await _client.get(uri, headers: headers)
        : await _client.post(uri, headers: headers, body: jsonEncode(body ?? {}));

    final payload = _decode(response.body);
    if (response.statusCode == 401 && requiresAuth && allowRefresh) {
      final refreshed = await _refresh();
      if (refreshed) {
        return _request(
          method,
          path,
          query: query,
          body: body,
          requiresAuth: requiresAuth,
          allowRefresh: false,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || payload['success'] == false) {
      throw ApiException(
        (payload['error'] ?? payload['message'] ?? 'Falha de comunicacao com a API').toString(),
        statusCode: response.statusCode,
      );
    }
    return payload;
  }

  Future<bool> _refresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final response = await _client.post(
        ApiConfig.endpoint('auth/refresh.php'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      final payload = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || payload['success'] != true) {
        await _tokenStore.clear();
        return false;
      }
      final data = Map<String, dynamic>.from(payload['data'] as Map? ?? const {});
      final tokens = Map<String, dynamic>.from(data['tokens'] as Map? ?? data);
      final access = tokens['access_token']?.toString();
      final refresh = tokens['refresh_token']?.toString() ?? refreshToken;
      if (access == null || access.isEmpty) {
        await _tokenStore.clear();
        return false;
      }
      await _tokenStore.save(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      await _tokenStore.clear();
      return false;
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Resposta invalida da API');
  }

  void dispose() => _client.close();
}
