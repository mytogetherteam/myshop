import 'dart:io';
import 'package:crypto/crypto.dart';

void main() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://api.mytogether.org'));
    final response = await request.close();
    
    final cert = response.certificate;
    if (cert != null) {
      final List<int> der = cert.der as List<int>;
      final fingerprint = sha256.convert(der).toString().toLowerCase();
      print('api.mytogether.org FINGERPRINT: $fingerprint');
    } else {
      print('No certificate found');
    }
  } catch (e) {
    print('Error: $e');
  }
}
