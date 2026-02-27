import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'https://maa-sharda-backend-production.up.railway.app';

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

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.get(uri, headers: _getHeaders());
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return http.post(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
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
}
