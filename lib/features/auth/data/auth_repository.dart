import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user.dart';

class AuthRepository {
  AuthRepository(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  Future<User> login(String email, String password) async {
    final data = await _api.login(email, password);
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() => _api.logout();

  Future<User> validateSession() async {
    final user = await _api.getMe();
    await _prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
    return user;
  }

  User? getCurrentUser() {
    final raw = _prefs.getString(AppConfig.userKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => _prefs.getString(AppConfig.tokenKey) != null;
}
