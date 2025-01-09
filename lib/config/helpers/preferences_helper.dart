import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static PreferencesHelper? _instance;
  static late SharedPreferences _preferences;

  // Singleton instance
  static PreferencesHelper get instance {
    _instance ??= PreferencesHelper._(); // Initialize _instance if null
    return _instance!;
  }

  PreferencesHelper._();

  // Initialize preferences in main.dart or at app startup
  static Future<void> init() async {
    print("init done");
    _preferences = await SharedPreferences.getInstance();
  }

  // String preference
  String getString(String key, {String defaultValue = ''}) {
    return _preferences.getString(key) ?? defaultValue;
  }

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  // Bool preference
  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences.getBool(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  // Int preference
  int getInt(String key, {int defaultValue = 0}) {
    return _preferences.getInt(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) {
    return _preferences.setInt(key, value);
  }

  // Double preference
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences.getDouble(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) {
    return _preferences.setDouble(key, value);
  }

  // Check if a key exists
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }

  // Remove preference
  Future<bool> remove(String key) {
    return _preferences.remove(key);
  }

  // Clear all preferences
  Future<bool> clear() {
    return _preferences.clear();
  }
}
