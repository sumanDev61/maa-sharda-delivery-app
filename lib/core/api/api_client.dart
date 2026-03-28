import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prodUrl =
      'https://maa-sharda-backend-production.up.railway.app';

  static bool _isLocalHost(String host) {
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1' || host.endsWith('.local')) {
      return true;
    }
    if (host.startsWith('10.')) return true;
    if (host.startsWith('192.168.')) return true;
    if (host.startsWith('172.')) {
      final parts = host.split('.');
      if (parts.length > 1) {
        final second = int.tryParse(parts[1]);
        if (second != null && second >= 16 && second <= 31) return true;
      }
    }
    return false;
  }

  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) {
      final fixedEnv = env.replaceAll('wailway', 'railway');
      final parsed = Uri.tryParse(fixedEnv);
      final host = (parsed?.host.isNotEmpty ?? false)
          ? parsed!.host
          : (Uri.tryParse('https://$fixedEnv')?.host ?? '');
      if (kReleaseMode && _isLocalHost(host)) {
        return _prodUrl;
      }
      return fixedEnv;
    }
    return _prodUrl;
  }
}

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _riderToken;
  String? _riderId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _riderToken = prefs.getString('rider_token');
    _riderId = prefs.getString('rider_id');
  }

  Future<void> setAuthSession(String token, String riderId) async {
    _riderToken = token;
    _riderId = riderId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rider_token', token);
    await prefs.setString('rider_id', riderId);
  }

  Future<void> clearSession() async {
    _riderToken = null;
    _riderId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rider_token');
    await prefs.remove('rider_id');
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_riderId != null) {
      headers['x-rider-id'] = _riderId!;
    }
    if (_riderToken != null) {
      headers['Authorization'] = 'Bearer $_riderToken';
    }
    return headers;
  }

  Map<String, String> _getUploadHeaders() {
    // Do not set Content-Type here; MultipartRequest will set it with boundary.
    final headers = <String, String>{'Accept': 'application/json'};
    if (_riderId != null) {
      headers['x-rider-id'] = _riderId!;
    }
    if (_riderToken != null) {
      headers['Authorization'] = 'Bearer $_riderToken';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.get(uri, headers: _getHeaders());
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.post(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.put(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.delete(uri, headers: _getHeaders());
  }

  Future<Map<String, dynamic>> uploadRiderDocument({
    required String doc,
    required File file,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/delivery/profile/documents/upload');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_getUploadHeaders());
    req.fields['doc'] = doc;
    req.files.add(await http.MultipartFile.fromPath('image', file.path));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    final json = body.isNotEmpty
        ? (jsonDecode(body) as Map<String, dynamic>)
        : <String, dynamic>{};
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(json['error']?.toString() ?? 'upload failed');
    }
    return json;
  }
}
