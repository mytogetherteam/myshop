import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';

class StorageService {
  static const String _keyToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserInfo = 'user_info';
  static const String _keyNotificationHandled =
      'notification_permission_handled';
  static const String _keySelectedShopId = 'selected_shop_id';
  static const String _keyLanguage = 'app_language';
  static const String _keyMenuWarningSeen = 'menu_warning_seen';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLastMissedOrderCheck = 'last_missed_order_check_ms';

  static final StorageService instance = StorageService._();

  late final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;
  bool _initialized = false;

  StorageService._();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _ensureInitialized();
    await _secureStorage.write(key: _keyToken, value: token);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getToken() async {
    await _ensureInitialized();
    return await _secureStorage.read(key: _keyToken);
  }

  Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> saveUserInfo(UserInfo userInfo) async {
    await _ensureInitialized();
    await _secureStorage.write(
        key: _keyUserInfo, value: json.encode(userInfo.toJson()));
  }

  Future<UserInfo?> getUserInfo() async {
    await _ensureInitialized();
    final data = await _secureStorage.read(key: _keyUserInfo);
    if (data == null) return null;
    try {
      return UserInfo.fromJson(json.decode(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _ensureInitialized();
    await _secureStorage.delete(key: _keyToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserInfo);
    await _prefs!.remove(_keyUserInfo); // Clean up legacy plaintext storage if exists
    await _prefs!.remove(_keySelectedShopId);
    await _prefs!.remove(_keyLanguage);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setNotificationHandled(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_keyNotificationHandled, value);
  }

  Future<bool> isNotificationHandled() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyNotificationHandled) ?? false;
  }

  static const String _keySystemAlertHandled = 'system_alert_permission_handled';

  Future<void> setSystemAlertHandled(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_keySystemAlertHandled, value);
  }

  Future<bool> isSystemAlertHandled() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keySystemAlertHandled) ?? false;
  }

  static const String _keyPhoneSetupGuideSeen = 'phone_setup_guide_seen';

  Future<void> setPhoneSetupGuideSeen() async {
    await _ensureInitialized();
    await _prefs!.setBool(_keyPhoneSetupGuideSeen, true);
  }

  Future<bool> isPhoneSetupGuideSeen() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyPhoneSetupGuideSeen) ?? false;
  }

  Future<void> saveSelectedShopId(int shopId) async {
    await _ensureInitialized();
    await _prefs!.setInt(_keySelectedShopId, shopId);
    // Also mirror as 'bg_shop_id' for the background service isolate
    await _prefs!.setInt('bg_shop_id', shopId);
  }

  Future<int?> getSelectedShopId() async {
    await _ensureInitialized();
    return _prefs!.getInt(_keySelectedShopId);
  }

  Future<void> removeSelectedShopId() async {
    await _ensureInitialized();
    await _prefs!.remove(_keySelectedShopId);
  }

  Future<void> setMenuWarningSeen() async {
    await _ensureInitialized();
    await _prefs!.setBool(_keyMenuWarningSeen, true);
  }

  Future<bool> isMenuWarningSeen() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyMenuWarningSeen) ?? false;
  }

  Future<void> saveLanguage(String langCode) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyLanguage, langCode);
  }

  Future<String> getLanguage() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyLanguage) ?? 'en'; // default English
  }

  Future<void> saveThemeMode(String themeModeStr) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyThemeMode, themeModeStr);
  }

  Future<String?> getThemeMode() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyThemeMode);
  }

  /// Timestamp (ms since epoch) of when user last saw the missed-order warning.
  Future<int> getLastMissedOrderCheckMs() async {
    await _ensureInitialized();
    return _prefs!.getInt(_keyLastMissedOrderCheck) ?? 0;
  }

  Future<void> setLastMissedOrderCheckMs(int ms) async {
    await _ensureInitialized();
    await _prefs!.setInt(_keyLastMissedOrderCheck, ms);
  }
}
