import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation — registers a visibilitychange listener that fires
/// [onVisible] whenever the user switches back to the PWA tab.
class WebSocketVisibilityHelper {
  static void registerVisibilityListener(void Function() onVisible) {
    web.document.addEventListener(
      'visibilitychange',
      (web.Event _) {
        if (web.document.visibilityState == 'visible') {
          onVisible();
        }
      }.toJS,
    );
  }
}
