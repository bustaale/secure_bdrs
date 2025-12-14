import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security Service
/// Handles encryption, hashing, access control, and data security
class SecurityService {
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _lastSecurityCheckKey = 'last_security_check';

  /// Hash Password (for secure storage)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate Encryption Key
  static String generateEncryptionKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Simple Encryption (for sensitive data)
  /// Note: For production, use proper encryption libraries like pointycastle
  static String encryptData(String data, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);
      
      // Simple XOR encryption (for demo - use proper encryption in production)
      final encrypted = List<int>.generate(
        dataBytes.length,
        (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return base64Encode(encrypted);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Simple Decryption
  static String decryptData(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final encrypted = base64Decode(encryptedData);
      
      // Simple XOR decryption
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Get or Create Encryption Key
  static Future<String> getOrCreateEncryptionKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? key = prefs.getString(_encryptionKeyKey);
      
      if (key == null || key.isEmpty) {
        key = generateEncryptionKey();
        await prefs.setString(_encryptionKeyKey, key);
      }
      
      return key;
    } catch (e) {
      throw Exception('Failed to get encryption key: $e');
    }
  }

  /// Encrypt Sensitive Data
  static Future<String> encryptSensitiveData(String data) async {
    try {
      final key = await getOrCreateEncryptionKey();
      return encryptData(data, key);
    } catch (e) {
      throw Exception('Failed to encrypt sensitive data: $e');
    }
  }

  /// Decrypt Sensitive Data
  static Future<String> decryptSensitiveData(String encryptedData) async {
    try {
      final key = await getOrCreateEncryptionKey();
      return decryptData(encryptedData, key);
    } catch (e) {
      throw Exception('Failed to decrypt sensitive data: $e');
    }
  }

  /// Hash Data for Integrity Check
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify Data Integrity
  static bool verifyDataIntegrity(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Sanitize Input (prevent injection attacks)
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  /// Validate Access Role
  static bool hasAccess(String userRole, List<String> allowedRoles) {
    return allowedRoles.contains(userRole);
  }

  /// Check if User Can Edit Records
  static bool canEditRecord(String userRole) {
    return hasAccess(userRole, ['admin', 'clerk', 'registrar']);
  }

  /// Check if User Can Delete Records
  static bool canDeleteRecord(String userRole) {
    return hasAccess(userRole, ['admin', 'registrar']);
  }

  /// Check if User Can Submit to Government
  static bool canSubmitToGovernment(String userRole) {
    return hasAccess(userRole, ['admin', 'registrar']);
  }

  /// Check if User Can View All Records
  static bool canViewAllRecords(String userRole) {
    return hasAccess(userRole, ['admin', 'clerk', 'registrar']);
  }

  /// Generate Secure Token
  static String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
    final data = '$timestamp-$random';
    return hashData(data).substring(0, 32);
  }

  /// Record Security Event
  static Future<void> recordSecurityEvent(String event, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final eventData = {
        'event': event,
        'userId': userId,
        'timestamp': timestamp,
      };
      
      // Store last event (in production, use proper logging service)
      await prefs.setString('last_security_event', jsonEncode(eventData));
      await prefs.setString(_lastSecurityCheckKey, timestamp);
    } catch (e) {
      // Log error but don't throw
      print('Failed to record security event: $e');
    }
  }

  /// Get Last Security Check Time
  static Future<DateTime?> getLastSecurityCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_lastSecurityCheckKey);
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mask Sensitive Data (for display)
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) return '****';
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return '$visible$masked';
  }

  /// Mask Phone Number
  static String maskPhoneNumber(String phone) {
    if (phone.length <= 4) return '****';
    final last4 = phone.substring(phone.length - 4);
    return '****$last4';
  }

  /// Mask Email
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '****@****';
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '**@$domain';
    }
    return '${username.substring(0, 2)}***@$domain';
  }

  /// Mask National ID
  static String maskNationalId(String id) {
    if (id.length <= 4) return '****';
    final last4 = id.substring(id.length - 4);
    return '****$last4';
  }

  /// Validate Security Token
  static bool isValidToken(String token, int maxAgeMinutes) {
    // In production, implement proper token validation with expiration
    return token.isNotEmpty && token.length >= 16;
  }

  /// Check if Data Needs Encryption
  static bool isSensitiveField(String fieldName) {
    final sensitiveFields = [
      'nationalId',
      'idNumber',
      'phone',
      'email',
      'password',
      'id',
    ];
    return sensitiveFields.any((field) => 
      fieldName.toLowerCase().contains(field.toLowerCase())
    );
  }
}

