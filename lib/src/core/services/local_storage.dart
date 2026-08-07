import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._(this._preferences);

  static const authTokenKey = 'auth_token';
  static const selectedStaffIdKey = 'selected_staff_id';

  final SharedPreferences _preferences;

  static Future<LocalStorageService> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStorageService._(preferences);
  }

  bool get hasAuthenticatedSession {
    final token = getString(authTokenKey)?.trim();
    return token != null && token.isNotEmpty;
  }

  String? getString(String key) => _preferences.getString(key);

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  int? getInt(String key) => _preferences.getInt(key);

  Future<bool> setInt(String key, int value) {
    return _preferences.setInt(key, value);
  }

  Future<bool> remove(String key) => _preferences.remove(key);

  Future<bool> clear() => _preferences.clear();
}
