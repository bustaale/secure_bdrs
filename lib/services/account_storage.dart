import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AccountStorage {
  static const String _accountsKey = 'stored_accounts';
  
  // Store a new account
  static Future<bool> createAccount(String name, String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAccounts = await getAccounts();
      
      // Check if email already exists
      if (existingAccounts.any((account) => account['email'].toLowerCase() == email.toLowerCase())) {
        return false; // Email already exists
      }
      
      // Create new account
      final newAccount = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'email': email.toLowerCase(),
        'password': password, // In production, this should be hashed
        'role': 'clerk',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      existingAccounts.add(newAccount);
      await prefs.setString(_accountsKey, jsonEncode(existingAccounts));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get all stored accounts
  static Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);
      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson) as List<dynamic>;
        return accountsList.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }
          return Map<String, dynamic>.from(item as Map);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // Validate login credentials
  static Future<User?> validateLogin(String email, String password) async {
    try {
      final accounts = await getAccounts();
      final account = accounts.firstWhere(
        (account) => account['email'].toLowerCase() == email.toLowerCase() && 
                    account['password'] == password,
        orElse: () => {},
      );
      
      if (account.isNotEmpty) {
        return User(
          id: account['id'],
          name: account['name'],
          email: account['email'],
          role: account['role'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Check if email exists
  static Future<bool> emailExists(String email) async {
    try {
      final accounts = await getAccounts();
      return accounts.any((account) => account['email'].toLowerCase() == email.toLowerCase());
    } catch (e) {
      return false;
    }
  }
}
