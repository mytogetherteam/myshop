import 'package:flutter/foundation.dart';

/// Lightweight logging facade used across the app.
///
/// All channels are no-ops in release builds (`kReleaseMode`) so production
/// users never pay the cost of building log strings, and emoji-laden trace
/// output never reaches end-user devices. Use one of the named channels
/// (`network`, `lifecycle`, `auth`, `realtime`) so it's easy to silence a
/// single category later by changing this file alone.
class AppLogger {
  AppLogger._();

  /// HTTP request/response traces. Use from `*_service.dart` files.
  static void network(String message) {
    if (kReleaseMode) return;
    debugPrint('[net] $message');
  }

  /// App lifecycle, auth state changes, navigation decisions.
  static void lifecycle(String message) {
    if (kReleaseMode) return;
    debugPrint('[life] $message');
  }

  /// WebSocket / FCM / push notification events.
  static void realtime(String message) {
    if (kReleaseMode) return;
    debugPrint('[rt] $message');
  }

  /// Errors that were caught but not rethrown. Always logged, including in
  /// release (kept on `debugPrint` which is rate-limited by Flutter).
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[err] $message${error != null ? ': $error' : ''}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  /// Catch-all ad-hoc debug print. Prefer the more specific channels above.
  static void debug(String message) {
    if (kReleaseMode) return;
    debugPrint('[dbg] $message');
  }
}
