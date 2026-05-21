import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _restaurantKey = 'settings_restaurant_name';
  static const _taxKey = 'settings_tax_rate';
  static const _themeKey = 'settings_theme_mode';

  String restaurantName = 'My Restaurant';
  double taxRate = AppConfig.taxRate;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    restaurantName = _prefs.getString(_restaurantKey) ?? restaurantName;
    taxRate = _prefs.getDouble(_taxKey) ?? AppConfig.taxRate;
    final theme = _prefs.getString(_themeKey);
    themeMode = switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> save({
    String? restaurantName,
    double? taxRate,
    ThemeMode? themeMode,
  }) async {
    if (restaurantName != null) {
      this.restaurantName = restaurantName;
      await _prefs.setString(_restaurantKey, restaurantName);
    }
    if (taxRate != null) {
      this.taxRate = taxRate;
      await _prefs.setDouble(_taxKey, taxRate);
    }
    if (themeMode != null) {
      this.themeMode = themeMode;
      await _prefs.setString(
        _themeKey,
        switch (themeMode) {
          ThemeMode.dark => 'dark',
          ThemeMode.light => 'light',
          _ => 'system',
        },
      );
    }
    notifyListeners();
  }
}
