import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/company_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  CompanySettings _settings = CompanySettings();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;

  CompanySettings get settings => _settings;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _db.getSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(CompanySettings newSettings) async {
    _settings = newSettings;
    await _db.saveSettings(newSettings);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
