import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'appConfig.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();
  static const _accessKey = 'relia_access_token';
  static const _refreshKey = 'relia_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;

  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
  }

  Future<void> _storeSession(Map<String, dynamic> response) async {
    _accessToken = response['accessToken'] as String?;
    _refreshToken = response['refreshToken'] as String?;
    if (_accessToken == null || _refreshToken == null) {
      throw ApiException('Сервер не вернул сессию');
    }
    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    late http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
        break;
      default:
        throw ApiException('Неподдерживаемый HTTP метод');
    }
    if (response.statusCode == 401 && allowRefresh && await refresh()) {
      return _request(method, path, body: body, allowRefresh: false);
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          message = error['message']?.toString();
        }
      }
      throw ApiException(message ?? 'Ошибка запроса', response.statusCode);
    }
    return decoded;
  }

  Future<void> login(String username, String password) async {
    final response =
        await _request(
              'POST',
              '/auth/login',
              body: {'username': username, 'password': password},
              allowRefresh: false,
            )
            as Map<String, dynamic>;
    await _storeSession(response);
  }

  Future<void> register(String username, String password) async {
    final response =
        await _request(
              'POST',
              '/auth/register',
              body: {'username': username, 'password': password},
              allowRefresh: false,
            )
            as Map<String, dynamic>;
    await _storeSession(response);
  }

  Future<bool> refresh() async {
    if (_refreshToken == null) return false;
    try {
      final response =
          await _request(
                'POST',
                '/auth/refresh',
                body: {'refreshToken': _refreshToken},
                allowRefresh: false,
              )
              as Map<String, dynamic>;
      await _storeSession(response);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<bool> restoreSession() async {
    if (_accessToken == null && _refreshToken == null) return false;
    try {
      await _request('GET', '/users/me');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout');
    } finally {
      await clearSession();
    }
  }

  Future<void> upsertAnswer(String questionKey, Object answer) async {
    await _request(
      'POST',
      '/onboarding/answers',
      body: {'questionKey': questionKey, 'answer': answer},
    );
  }

  Future<Map<String, dynamic>> partnerAnswers() async {
    final rows =
        await _request('GET', '/onboarding/answers/me') as List<dynamic>;
    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['questionKey'] as String: row['answer'],
    };
  }

  Future<List<dynamic>> events() async =>
      await _request('GET', '/events') as List<dynamic>;
  Future<List<dynamic>> todos() async =>
      await _request('GET', '/todos') as List<dynamic>;
  Future<List<dynamic>> reminders() async =>
      await _request('GET', '/reminders') as List<dynamic>;
  Future<List<dynamic>> messages() async =>
      await _request('GET', '/chat/messages?limit=100') as List<dynamic>;

  Future<Map<String, dynamic>> sendMessage(String message) async =>
      await _request('POST', '/chat/messages', body: {'message': message})
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> suggestDate(double budget) async =>
      await _request(
            'POST',
            '/assistant/suggest-date',
            body: {'budget': budget},
          )
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> recommend(String type) async =>
      await _request('POST', '/assistant/recommend', body: {'type': type})
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> analyzeRelationship() async =>
      await _request('POST', '/assistant/analyze-relationship', body: {})
          as Map<String, dynamic>;

  WebSocketChannel chatSocket() {
    if (_accessToken == null) throw ApiException('Нет активной сессии');
    final token = Uri.encodeQueryComponent(_accessToken!);
    return WebSocketChannel.connect(
      Uri.parse('${AppConfig.wsBaseUrl}/ws/chat?access_token=$token'),
    );
  }
}
