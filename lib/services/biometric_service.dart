import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Biometric Authentication Service
/// Handles fingerprint, face ID, and other biometric authentication
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  /// Static method to check if biometric is available
  static Future<bool> isAvailable() async {
    try {
      final service = BiometricService();
      return await service.isDeviceSupported() && await service.canCheckBiometrics();
    } catch (e) {
      return false;
    }
  }

  /// Static method to check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get saved email for biometric login
  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyBiometricEmail);
    } catch (e) {
      return null;
    }
  }

  /// Enable biometric authentication and save credentials
  static Future<void> enableBiometric(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Encrypt password before saving (simple base64 for now, can be enhanced)
      final encodedPassword = base64Encode(utf8.encode(password));
      
      await prefs.setString(_keyBiometricEmail, email);
      await prefs.setString(_keyBiometricPassword, encodedPassword);
      await prefs.setBool(_keyBiometricEnabled, true);
    } catch (e) {
      throw Exception('Failed to enable biometric: $e');
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBiometricEmail);
      await prefs.remove(_keyBiometricPassword);
      await prefs.setBool(_keyBiometricEnabled, false);
    } catch (e) {
      throw Exception('Failed to disable biometric: $e');
    }
  }

  /// Authenticate and return saved credentials
  static Future<Map<String, String>?> authenticate() async {
    try {
      final service = BiometricService();
      
      // Check if biometric is enabled
      if (!await isBiometricEnabled()) {
        throw Exception('Biometric authentication is not enabled');
      }

      // Perform biometric authentication
      final authenticated = await service._performAuthentication(
        reason: 'Please authenticate to login',
      );

      if (!authenticated) {
        return null;
      }

      // Get saved credentials
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_keyBiometricEmail);
      final encodedPassword = prefs.getString(_keyBiometricPassword);

      if (email == null || encodedPassword == null) {
        throw Exception('No saved credentials found');
      }

      // Decrypt password
      final password = utf8.decode(base64Decode(encodedPassword));

      return {
        'email': email,
        'password': password,
      };
    } catch (e) {
      throw Exception('Biometric authentication failed: $e');
    }
  }

  /// Internal method to perform biometric authentication
  Future<bool> _performAuthentication({
    String reason = 'Please authenticate to access the app',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if device supports biometrics
      if (!await isDeviceSupported()) {
        throw Exception('Device does not support biometric authentication');
      }

      // Check if biometrics are available
      if (!await canCheckBiometrics()) {
        throw Exception('No biometrics enrolled. Please set up fingerprint or face ID in device settings.');
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device credentials
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          throw Exception('Biometric authentication is not available on this device');
        case 'NotEnrolled':
          throw Exception('No biometrics enrolled. Please set up fingerprint or face ID in device settings.');
        case 'LockedOut':
          throw Exception('Biometric authentication is locked. Please try again later.');
        case 'PermanentlyLockedOut':
          throw Exception('Biometric authentication is permanently locked. Please use password.');
        default:
          throw Exception('Biometric authentication failed: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error during biometric authentication: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Check if biometrics are available (enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }


  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }


  /// Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric';
    }
  }
}
