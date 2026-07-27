import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._(this._preferences);

  final SharedPreferences _preferences;

  static Future<LocalStorageService> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStorageService._(preferences);
  }

  String? getString(String key) => _preferences.getString(key);

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  Future<bool> remove(String key) => _preferences.remove(key);

  Future<bool> clear() => _preferences.clear();
}
