import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CertificatePinningInterceptor extends Interceptor {
  final Dio dio;
  final Map<String, List<String>> _hostPins = {};

  CertificatePinningInterceptor(this.dio) {
    _initPins();
    if (!kIsWeb) {
      _setupPinning();
    }
  }

  void _initPins() {
    _hostPins['myshopdemoapi-production.up.railway.app'] = [
      'd0971986fdb19fe936da41e20dfff66ced9754c1ba65660dd7b805cd69b7b131',
    ];

    _hostPins['myshopdemoapi-staging.up.railway.app'] = [
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    ];
  }

  void _setupPinning() {
    // Certificate pinning uses dart:io types (IOHttpClientAdapter,
    // X509Certificate) which are not available on web. The kIsWeb guard
    // in the constructor prevents this from running in a browser.
    //
    // We dynamically interact with the adapter to avoid compile-time
    // references to dart:io types in web builds.
    try {
      final dynamic adapter = dio.httpClientAdapter;
      // On native platforms the adapter is IOHttpClientAdapter; on web it
      // is a browser-based adapter. We check at runtime to be safe.
      if (adapter.runtimeType.toString().contains('IOHttpClientAdapter')) {
        adapter.validateCertificate =
            (dynamic cert, String host, int port) {
          debugPrint(
            'CertificatePinning: validateCertificate called for host: $host, port: $port, hasCert: ${cert != null}',
          );
          if (host == 'localhost' ||
              host == '127.0.0.1' ||
              host == '10.0.2.2') {
            return true;
          }
          if (cert == null) return false;

          // If the host is not pinned, allow standard validation
          if (!_hostPins.containsKey(host)) return true;

          // Calculate the SHA-256 fingerprint of the certificate.
          // cert.der returns List<int> on native.
          // ignore: avoid_dynamic_calls
          final List<int> der = cert.der as List<int>;
          final fingerprint = sha256.convert(der).toString().toLowerCase();
          final allowedPins = _hostPins[host] ?? [];

          for (final pin in allowedPins) {
            final cleanPin = pin
                .replaceAll('sha256/', '')
                .replaceAll(':', '')
                .replaceAll(' ', '')
                .toLowerCase();
            if (fingerprint == cleanPin) {
              debugPrint(
                'CertificatePinning: Successfully validated certificate for $host',
              );
              return true;
            }
          }

          debugPrint(
            'CertificatePinning: FAILED to validate certificate for $host. Fingerprint was: $fingerprint',
          );
          return false;
        };
      }
    } catch (e) {
      // On web or if the adapter doesn't support pinning, silently skip.
      debugPrint('CertificatePinning: skipped ($e)');
    }
  }
}
