import '../config/env_config.dart';

/// Resolves stored file keys / relative paths to loadable URLs.
/// Mirrors backend `toPublicFileUrl` in file-url.util.ts.
class FileUrlUtil {
  static const String s3PublicBase =
      'https://my-together-moonlight201.s3.ap-southeast-1.amazonaws.com';

  static String? resolve(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    if (str.startsWith('data:')) return str;

    final path = str.startsWith('/') ? str.substring(1) : str;

    if (path.startsWith('uploads/')) {
      return '${EnvConfig.apiBaseUrl}/$path';
    }

    return '$s3PublicBase/$path';
  }
}
