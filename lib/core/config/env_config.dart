class EnvConfig {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const String _baseUrlStaging =
      'https://myshopdemoapi-production.up.railway.app';
  static const String _baseUrlProduction =
      'https://myshopdemoapi-production.up.railway.app';

  static const String _wsUrlStaging =
      'wss://myshopdemoapi-production.up.railway.app/ws/websocket';
  static const String _wsUrlProduction =
      'wss://myshopdemoapi-production.up.railway.app/ws/websocket';

  static String get apiBaseUrl {
    if (appEnv == 'staging') return _baseUrlStaging;
    return _baseUrlProduction;
  }

  static String get wsUrl {
    if (appEnv == 'staging') return _wsUrlStaging;
    return _wsUrlProduction;
  }

  static const String apiPrefix = '/api/shop';

  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);

  static String get fullApiUrl => '$apiBaseUrl$apiPrefix';

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDebug => appEnv == 'development';
}

//ajldksf
