import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyAutoBackup = 'auto_backup_enabled';
  static const String _keyLanguage = 'language';
  static const String _keyBackupFrequency = 'backup_frequency';
  static const String _keyLastBackup = 'last_backup_date';
  static const String _keyAutoLock = 'auto_lock_enabled';
  static const String _keyAutoLockMinutes = 'auto_lock_minutes';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  // Notifications
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // Auto Backup
  static Future<bool> getAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoBackup) ?? false;
  }

  static Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoBackup, value);
  }

  // Language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  // Backup Frequency
  static Future<String> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackupFrequency) ?? 'weekly';
  }

  static Future<void> setBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBackupFrequency, frequency);
  }

  // Last Backup Date
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_keyLastBackup);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  static Future<void> setLastBackupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastBackup, date.toIso8601String());
  }

  // Auto Lock
  static Future<bool> getAutoLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoLock) ?? true;
  }

  static Future<void> setAutoLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoLock, value);
  }

  static Future<int> getAutoLockMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoLockMinutes) ?? 5;
  }

  static Future<void> setAutoLockMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLockMinutes, minutes);
  }

  // Biometric Authentication
  static Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, value);
  }

  // Clear all settings
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyAutoBackup);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyBackupFrequency);
    await prefs.remove(_keyLastBackup);
    await prefs.remove(_keyAutoLock);
    await prefs.remove(_keyAutoLockMinutes);
    await prefs.remove(_keyBiometricEnabled);
  }
}
