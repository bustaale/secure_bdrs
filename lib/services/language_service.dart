import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _locale.languageCode) {
      _locale = Locale(languageCode);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
        print('✅ Language changed to: $languageCode');
      } catch (e) {
        print('Error saving language: $e');
      }
      
      // Update GetX locale system
      try {
        Get.updateLocale(_locale);
        print('✅ GetX locale updated to: ${_locale.languageCode}');
      } catch (e) {
        print('⚠️ GetX locale update failed: $e');
      }
      
      // Notify listeners immediately for instant UI update
      notifyListeners();
      
      // Print for debugging
      print('📢 Notified listeners about locale change: ${_locale.languageCode}');
    } else {
      print('ℹ️ Language already set to: $languageCode');
    }
  }

  Future<void> setEnglish() async {
    await setLanguage('en');
  }

  Future<void> setKiswahili() async {
    await setLanguage('sw');
  }

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isKiswahili => _locale.languageCode == 'sw';
  
  String get languageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'English';
    }
  }
  
  List<String> get supportedLanguages => ['en', 'sw'];
}

