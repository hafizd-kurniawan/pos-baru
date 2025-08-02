import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _firstLaunchKey = 'first_launch';
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Auth token methods
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // User data methods
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _secureStorage.write(key: _userKey, value: jsonString);
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _secureStorage.read(key: _userKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }
  
  static Future<void> clearUserData() async {
    await _secureStorage.delete(key: _userKey);
  }
  
  // Theme methods
  static Future<void> saveThemeMode(String themeMode) async {
    await _prefs.setString(_themeKey, themeMode);
  }
  
  static String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'light';
  }
  
  // Language methods
  static Future<void> saveLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }
  
  static String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'id';
  }
  
  // First launch methods
  static Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }
  
  static bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }
  
  // Generic methods
  static Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  static String? getString(String key) {
    return _prefs.getString(key);
  }
  
  static Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  static Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  static Future<void> saveDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }
  
  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}