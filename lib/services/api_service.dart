import 'dart:convert';
import 'package:http/http.dart' as http;
import "../constants.dart";
import "../utils/secure_storage.dart";

class ApiService {
  final SecureStorage _storage = SecureStorage();

  Future<Map<String, String>> _defaultHeaders() async {
    final token = await _storage.readToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse(API.baseUrl + path);
    final headers = await _defaultHeaders();
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse(API.baseUrl + path);
    final headers = await _defaultHeaders();
    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  // additional helpers (put, delete) can be added later
}
