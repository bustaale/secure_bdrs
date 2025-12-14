import 'dart:async';

// For demo: an in-memory token store. Replace with flutter_secure_storage in production.
class SecureStorage {
  String? _token;
  Future<void> writeToken(String token) async {
    _token = token;
  }

  Future<String?> readToken() async {
    return _token;
  }

  Future<void> deleteToken() async {
    _token = null;
  }
}
