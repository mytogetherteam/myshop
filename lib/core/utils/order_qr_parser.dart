import 'dart:convert';

/// Extracts an order identifier from scanned QR payload text.
class OrderQrParser {
  OrderQrParser._();

  static String? parseOrderId(String? raw) {
    if (raw == null) return null;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final fromJson = _parseJson(trimmed);
    if (fromJson != null) return fromJson;

    final fromUrl = _parseUrl(trimmed);
    if (fromUrl != null) return fromUrl;

    final fromPrefix = _parsePrefix(trimmed);
    if (fromPrefix != null) return fromPrefix;

    if (_looksLikeOrderId(trimmed)) return trimmed;

    return null;
  }

  static String? _parseJson(String value) {
    if (!value.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      for (final key in const ['orderId', 'order_id', 'id']) {
        final candidate = map[key];
        if (candidate != null) {
          final id = candidate.toString().trim();
          if (id.isNotEmpty) return id;
        }
      }
    } catch (_) {}

    return null;
  }

  static String? _parseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;

    for (final key in const ['orderId', 'order_id', 'id']) {
      final candidate = uri.queryParameters[key];
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    final segments =
        uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i].toLowerCase();
      if (segment == 'order' || segment == 'orders') {
        final id = segments[i + 1].trim();
        if (_looksLikeOrderId(id)) return id;
      }
    }

    if (segments.isNotEmpty) {
      final last = segments.last.trim();
      if (_looksLikeOrderId(last)) return last;
    }

    return null;
  }

  static String? _parsePrefix(String value) {
    final lower = value.toLowerCase();
    for (final prefix in const ['order:', 'orders:']) {
      if (lower.startsWith(prefix)) {
        final id = value.substring(prefix.length).trim();
        if (_looksLikeOrderId(id)) return id;
      }
    }
    return null;
  }

  static bool _looksLikeOrderId(String value) {
    if (value.isEmpty || value.length > 64) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
  }
}
