import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _autoLockEnabled = true;
  int _autoLockMinutes = 5;
  bool _biometricEnabled = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoLockEnabled => _autoLockEnabled;
  int get autoLockMinutes => _autoLockMinutes;
  bool get biometricEnabled => _biometricEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _notificationsEnabled = await SettingsService.getNotificationsEnabled();
      _autoLockEnabled = await SettingsService.getAutoLockEnabled();
      _autoLockMinutes = await SettingsService.getAutoLockMinutes();
      _biometricEnabled = await SettingsService.getBiometricEnabled();
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await SettingsService.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setAutoLockEnabled(bool value) async {
    _autoLockEnabled = value;
    await SettingsService.setAutoLockEnabled(value);
    notifyListeners();
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes;
    await SettingsService.setAutoLockMinutes(minutes);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await SettingsService.setBiometricEnabled(value);
    notifyListeners();
  }
}

