import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebServiceWorkerMessageListener {
  static void start(void Function(Map<String, dynamic> data) onMessage) {
    void handler(web.MessageEvent event) {
      final raw = event.data;
      if (raw == null) return;

      final dartValue = raw.dartify();
      if (dartValue is Map) {
        onMessage(Map<String, dynamic>.from(dartValue));
      }
    }

    final handlerJs = handler.toJS;
    // FIX: Use addEventListener instead of onmessage= to avoid overwriting
    // Flutter Web Engine's own window.onmessage handler (platform channel).
    web.window.navigator.serviceWorker.addEventListener('message', handlerJs);
    web.window.addEventListener('message', handlerJs);
  }
}
