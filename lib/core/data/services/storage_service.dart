import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';

class StorageService {
  static const String _keyToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserInfo = 'user_info';
  static const String _keyNotificationHandled = 'notification_permission_handled';

  static final StorageService instance = StorageService._();
  StorageService._();

  Future<void> saveTokens({required String token, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<void> saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserInfo, json.encode(userInfo.toJson()));
  }

  Future<UserInfo?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserInfo);
    if (data == null) return null;
    return UserInfo.fromJson(json.decode(data));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserInfo);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setNotificationHandled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationHandled, value);
  }

  Future<bool> isNotificationHandled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationHandled) ?? false;
  }
}
