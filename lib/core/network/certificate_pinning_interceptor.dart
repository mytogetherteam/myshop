import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter
          .validateCertificate = (X509Certificate? cert, String host, int port) {
        debugPrint('CertificatePinning: validateCertificate called for host: $host, port: $port, hasCert: ${cert != null}');
        if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
          return true;
        }
        if (cert == null) return false;

        // If the host is not pinned, allow standard validation
        if (!_hostPins.containsKey(host)) return true;

        // Calculate the SHA-256 fingerprint of the certificate
        final fingerprint = sha256.convert(cert.der).toString().toLowerCase();
        final allowedPins = _hostPins[host] ?? [];

        for (final pin in allowedPins) {
          // Clean the pin string (e.g. remove "sha256/" prefix, spaces, colons)
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
  }
}
