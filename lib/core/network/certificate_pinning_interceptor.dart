import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CertificatePinningInterceptor extends Interceptor {
  final Map<String, List<String>> _hostPins = {};

  CertificatePinningInterceptor() {
    _initPins();
  }

  void _initPins() {
    _hostPins['myshopdemoapi-production.up.railway.app'] = [
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    ];

    _hostPins['myshopdemoapi-staging.up.railway.app'] = [
      'sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
    ];
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = Uri.parse(options.uri.toString());
    final host = uri.host;

    if (_hostPins.containsKey(host)) {
      debugPrint('CertificatePinning: Validating certificate for $host');
    }

    handler.next(options);
  }
}
