import 'dart:io';

void main() {
  final path = 'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  
  String content = file.readAsStringSync();

  // 1. Scaffold & AppBar Backgrounds
  content = content.replaceAll('backgroundColor: Colors.white,', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor,');
  
  // 2. Specific driver selection tile background
  content = content.replaceAll(': Colors.white,', ': Theme.of(context).cardColor,');
  // Revert any unintended changes from the above replace 
  content = content.replaceAll("_deliveryOption == 'PREPAID' ? Theme.of(context).cardColor : const Color(0xFF64748B)", "_deliveryOption == 'PREPAID' ? Colors.white : const Color(0xFF64748B)");
  content = content.replaceAll("_deliveryOption == 'NORMAL' ? Theme.of(context).cardColor : const Color(0xFF64748B)", "_deliveryOption == 'NORMAL' ? Colors.white : const Color(0xFF64748B)");

  // 3. TextFields Fill Colors
  content = content.replaceAll('fillColor: Colors.white,', 'fillColor: Theme.of(context).cardColor,');

  // 4. Hardcoded Text & Background Colors
  content = content.replaceAll('const Color(0xFFF8FAFC)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))');
  content = content.replaceAll('Color(0xFFF8FAFC)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))');
  
  content = content.replaceAll('const Color(0xFFE2E8F0)', 'Theme.of(context).dividerColor');
  content = content.replaceAll('Color(0xFFE2E8F0)', 'Theme.of(context).dividerColor');
  
  content = content.replaceAll('const Color(0xFF1E293B)', '(Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1E293B))');
  content = content.replaceAll('Color(0xFF1E293B)', '(Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1E293B))');
  
  content = content.replaceAll('const Color(0xFF94A3B8)', '(Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF94A3B8))');
  content = content.replaceAll('Color(0xFF94A3B8)', '(Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF94A3B8))');

  content = content.replaceAll('const Color(0xFFF1F5F9)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))');
  content = content.replaceAll('Color(0xFFF1F5F9)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))');
  
  // Fix const issues
  content = content.replaceAll('const (Theme.of(context)', '(Theme.of(context)');
  
  // Since we replace const Color() with dynamic Theme.of(context), we must strip "const " from decorations that now contain dynamic values
  // A naive way is to remove "const " before BorderSide, Border.all, BoxDecoration
  content = content.replaceAll('const BorderSide(color: Theme.of(context)', 'BorderSide(color: Theme.of(context)');
  content = content.replaceAll('const BoxDecoration(color: Theme.of(context)', 'BoxDecoration(color: Theme.of(context)');
  content = content.replaceAll('const BoxDecoration(border: Border.all(color: Theme.of(context)', 'BoxDecoration(border: Border.all(color: Theme.of(context)');
  
  // Also fix: "border: Border.all(color: Theme.of(context).dividerColor)," inside a const BoxDecoration needs removing const from the BoxDecoration
  // It's too complex to regex safely, so let's run a second pass if compile fails, or just try to replace `const BoxDecoration` with `BoxDecoration` where `Theme.of(context)` occurs inside.
  // The simplest is to run dart format and dart analyze to catch errors.

  file.writeAsStringSync(content);
  print('Fixed colors in order_detail_screen.dart');
}
