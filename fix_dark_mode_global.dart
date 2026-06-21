import 'dart:io';

void main() {
  final dir = Directory('d:\\my_shop\\lib\\features');
  final files = dir.listSync(recursive: true).where((e) => e.path.endsWith('.dart') && e is File).cast<File>();

  int changedFiles = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Backgrounds
    content = content.replaceAll('backgroundColor: Colors.white', 'backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white');
    content = content.replaceAll('fillColor: Colors.white', 'fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white');
    
    // Text colors
    content = content.replaceAll('const Color(0xFF1E293B)', '(Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))');
    content = content.replaceAll('Color(0xFF1E293B)', '(Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))');
    
    content = content.replaceAll('const Color(0xFF64748B)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))');
    content = content.replaceAll('Color(0xFF64748B)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))');
    
    content = content.replaceAll('const Color(0xFF94A3B8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8))');
    content = content.replaceAll('Color(0xFF94A3B8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8))');

    // Borders and dividers
    content = content.replaceAll('const Color(0xFFE2E8F0)', 'Theme.of(context).dividerColor');
    content = content.replaceAll('Color(0xFFE2E8F0)', 'Theme.of(context).dividerColor');
    
    content = content.replaceAll('const Color(0xFFF1F5F9)', '(Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))');
    content = content.replaceAll('Color(0xFFF1F5F9)', '(Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))');

    // Warning/Error Backgrounds
    content = content.replaceAll('const Color(0xFFFFF1F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))');
    content = content.replaceAll('Color(0xFFFFF1F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))');
    
    content = content.replaceAll('const Color(0xFFFFFBEB)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB))');
    content = content.replaceAll('Color(0xFFFFFBEB)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB))');

    // Clean up duplicated Theme.of if script was run before
    content = content.replaceAll('const (Theme.of(context)', '(Theme.of(context)');
    
    // Attempt basic const stripping
    content = content.replaceAll('const TextStyle(', 'TextStyle(');
    content = content.replaceAll('const Icon(', 'Icon(');
    content = content.replaceAll('const Padding(', 'Padding(');
    content = content.replaceAll('const Center(', 'Center(');
    content = content.replaceAll('const BoxDecoration(', 'BoxDecoration(');
    content = content.replaceAll('const BorderSide(', 'BorderSide(');
    content = content.replaceAll('const Border(', 'Border(');
    content = content.replaceAll('const Container(', 'Container(');
    content = content.replaceAll('const Row(', 'Row(');
    content = content.replaceAll('const Column(', 'Column(');
    content = content.replaceAll('const SizedBox(', 'SizedBox(');
    
    if (content != original) {
      file.writeAsStringSync(content);
      changedFiles++;
    }
  }

  print('Replaced colors in $changedFiles files.');
}
