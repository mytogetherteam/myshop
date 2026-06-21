/// Stub for non-web platforms — no-op so websocket_service.dart compiles
/// on Android, iOS, desktop, etc.
class WebSocketVisibilityHelper {
  static void registerVisibilityListener(void Function() onVisible) {
    // No-op on non-web platforms.
  }
}
