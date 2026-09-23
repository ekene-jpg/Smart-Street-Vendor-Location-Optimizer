import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/location.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'auth_token';

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> get isLoggedIn async => (await _token) != null;

  Map<String, String> _headers({bool auth = false, String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(body['error']?.toString() ?? 'Request failed (${res.statusCode})');
  }

  Future<AppUser> register(String fullName, String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: _headers(),
      body: jsonEncode({'full_name': fullName, 'email': email, 'password': password}),
    );
    final data = _decode(res);
    await _saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    await _saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<List<String>> fetchAreas() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/locations/areas'));
    final data = _decode(res);
    return List<String>.from(data['areas']);
  }

  Future<List<VendorLocation>> fetchLocations({String? area}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/locations').replace(
      queryParameters: area != null && area.isNotEmpty ? {'area': area} : null,
    );
    final res = await http.get(uri);
    final data = _decode(res);
    return (data['locations'] as List).map((e) => VendorLocation.fromJson(e)).toList();
  }

  Future<VendorLocation> fetchLocationDetail(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/locations/$id'));
    final data = _decode(res);
    final merged = {
      ...data,
      ...?data['feature'],
    };
    return VendorLocation.fromJson(merged);
  }

  Future<List<VendorLocation>> getRecommendations({
    String? area,
    Map<String, double>? weights,
  }) async {
    final token = await _token;
    if (token == null) throw ApiException('You must be logged in to request recommendations.');

    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/recommendations'),
      headers: _headers(auth: true, token: token),
      body: jsonEncode({
        if (area != null && area.isNotEmpty) 'area': area,
        if (weights != null) 'weights': weights,
      }),
    );
    final data = _decode(res);
    return (data['recommendations'] as List).map((e) => VendorLocation.fromJson(e)).toList();
  }
}
