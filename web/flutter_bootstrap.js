{{flutter_js}}
{{flutter_build_config}}

// Do not register Flutter's service worker — a previous custom worker
// unregistered itself and forced client.reload(), which broke PWA startup.
_flutter.loader.load();
