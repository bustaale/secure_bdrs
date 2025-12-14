import "package:flutter/material.dart";
import "../models/user.dart";
import "../services/auth_service.dart";
import "../services/account_storage.dart";
import "../utils/secure_storage.dart";

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  final SecureStorage _storage = SecureStorage();

  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final u = await _service.login(email.trim(), password);
      _loading = false;
      notifyListeners();
      if (u != null) {
        _user = u;
        // write a demo token
        await _storage.writeToken("demo_token_${u.id}");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // Ensure loading is stopped even if an error occurs
      _loading = false;
      notifyListeners();
      print('Login error in provider: $e');
      return false;
    }
  }

  Future<bool> createAccount(String name, String email, String password) async {
    _loading = true;
    notifyListeners();
    
    try {
      // Try Firebase Auth first
      final user = await _service.createAccountWithFirebase(name, email, password);
      
      if (user != null) {
        _user = user;
        await _storage.writeToken("firebase_token_${user.id}");
        _loading = false;
        notifyListeners();
        return true;
      }
      
      // Fallback to local storage if Firebase fails
      final success = await AccountStorage.createAccount(name, email, password);
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error creating account: $e');
      // Fallback to local storage
      try {
        final success = await AccountStorage.createAccount(name, email, password);
        _loading = false;
        notifyListeners();
        return success;
      } catch (e2) {
        _loading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<void> logout() async {
    _user = null;
    await _service.logout();
    await _storage.deleteToken();
    notifyListeners();
  }
}
