import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _load();
  }

  // Supported locales - must match ARB files
  static const supportedCodes = ['en', 'de', 'zh', 'ar'];

  Locale _locale = const Locale('de'); // Default German per user preference
  Locale get locale => _locale;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'de';
    if (supportedCodes.contains(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    if (!supportedCodes.contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
  }

  /// Sync from ConfigProvider language field
  void syncFromConfig(String? language) {
    if (language != null &&
        supportedCodes.contains(language) &&
        language != _locale.languageCode) {
      setLocale(language);
    }
  }
}
