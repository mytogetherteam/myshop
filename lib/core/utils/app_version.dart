import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static String _version = '1.0.0';
  static String _buildNumber = '1';
  static bool _initialized = false;

  /// Call once in main() before runApp()
  static Future<void> init() async {
    if (_initialized) return;
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
    _buildNumber = info.buildNumber;
    _initialized = true;
  }

  /// e.g. "1.0.0"
  static String get version => _version;

  /// e.g. "1.0.0 (1)"
  static String get fullVersion => 'v$_version ($buildNumber)';

  /// e.g. "1"
  static String get buildNumber => _buildNumber;
}
