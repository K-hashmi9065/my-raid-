import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

abstract class LocalStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> removeToken();
  Future<String?> getUserData();
  Future<void> saveUserData(String data);
  Future<void> removeUserData();
  Future<String?> getCachedTasks();
  Future<void> saveCachedTasks(String data);
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool value);
  Future<void> clearAll();
}

class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;

  LocalStorageImpl(this._prefs);

  @override
  Future<String?> getToken() async {
    return _prefs.getString(AppConstants.tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(AppConstants.tokenKey, token);
  }

  @override
  Future<void> removeToken() async {
    await _prefs.remove(AppConstants.tokenKey);
  }

  @override
  Future<String?> getUserData() async {
    return _prefs.getString(AppConstants.userKey);
  }

  @override
  Future<void> saveUserData(String data) async {
    await _prefs.setString(AppConstants.userKey, data);
  }

  @override
  Future<void> removeUserData() async {
    await _prefs.remove(AppConstants.userKey);
  }

  @override
  Future<String?> getCachedTasks() async {
    return _prefs.getString(AppConstants.tasksKey);
  }

  @override
  Future<void> saveCachedTasks(String data) async {
    await _prefs.setString(AppConstants.tasksKey, data);
  }

  @override
  Future<bool> isDarkMode() async {
    return _prefs.getBool(AppConstants.themeKey) ?? false;
  }

  @override
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(AppConstants.themeKey, value);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
