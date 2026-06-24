import 'dart:io';

void main() {
  final path = 'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  
  String content = file.readAsStringSync();

  // Dark Blue -> White in dark mode
  content = content.replaceAll('const Color(0xFF1E293B)', '(Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))');
  content = content.replaceAll('Color(0xFF1E293B)', '(Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))');
  
  // Grey -> Light Grey in dark mode
  content = content.replaceAll('const Color(0xFF64748B)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))');
  content = content.replaceAll('Color(0xFF64748B)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))');
  
  // Light Grey -> Lighter Grey in dark mode
  content = content.replaceAll('const Color(0xFF94A3B8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8))');
  content = content.replaceAll('Color(0xFF94A3B8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8))');

  // Strip const from Icon, TextStyle, Border, etc., that might contain these now-dynamic colors
  content = content.replaceAll('const Icon(PhosphorIcons', 'Icon(PhosphorIcons');
  content = content.replaceAll('const TextStyle(', 'TextStyle(');
  content = content.replaceAll('const Icon(Icons.', 'Icon(Icons.');
  
  // Also strip const from the ternary operators if they got duplicated
  content = content.replaceAll('const (Theme.of(context)', '(Theme.of(context)');

  file.writeAsStringSync(content);
  print('Fixed text colors in order_detail_screen.dart');
}
