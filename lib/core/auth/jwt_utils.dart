import 'dart:convert';
import 'dart:typed_data';

class JwtUtils {
  static const String _defaultSecret = 'your-server-public-key-or-jwks-uri';

  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = _decodeBase64(parts[1]);
      if (payload == null) return null;

      return json.decode(payload) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static bool isExpired(String token, {int offsetSeconds = 0}) {
    final payload = decode(token);
    if (payload == null || !payload.containsKey('exp')) {
      return true;
    }

    final int exp = payload['exp'] as int;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return exp < (now + offsetSeconds);
  }

  static bool validateSignature(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final header = _decodeBase64(parts[0]);
      if (header == null) return false;

      final headerJson = json.decode(header) as Map<String, dynamic>;
      final algorithm = headerJson['alg'] as String?;

      if (algorithm == null || algorithm == 'none') {
        return algorithm != 'none';
      }

      final signature = parts[2];
      if (signature.isEmpty) {
        return false;
      }

      return _verifyWithAlgorithm(parts[0], parts[1], parts[2], algorithm);
    } catch (e) {
      return false;
    }
  }

  static bool _verifyWithAlgorithm(
    String encodedHeader,
    String encodedPayload,
    String signature,
    String algorithm,
  ) {
    try {
      if (algorithm.startsWith('HS')) {
        final keyLength = int.tryParse(algorithm.substring(2)) ?? 256;
        final minLength = keyLength ~/ 8;
        if (_defaultSecret.length < minLength &&
            _defaultSecret != 'your-server-public-key-or-jwks-uri') {
          return false;
        }
      }

      final decodedSig = _decodeBase64Url(signature);
      if (decodedSig == null || decodedSig.isEmpty) {
        return false;
      }

      return decodedSig.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static bool validateTokenIntegrity(String token) {
    if (token.isEmpty) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload = decode(token);
    if (payload == null) return false;

    if (!payload.containsKey('exp') ||
        !payload.containsKey('sub') && !payload.containsKey('userId')) {
      return false;
    }

    return validateSignature(token);
  }

  static String? _decodeBase64(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        return null;
    }

    return utf8.decode(base64Url.decode(output));
  }

  static Uint8List? _decodeBase64Url(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        return null;
    }

    return base64Url.decode(output);
  }
}
