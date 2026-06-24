import 'dart:io';

void main() {
  final path = 'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  
  String content = file.readAsStringSync();

  // Fix bright pink/red backgrounds for dark mode
  content = content.replaceAll('const Color(0xFFFFF1F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))');
  content = content.replaceAll('Color(0xFFFFF1F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))');
  
  content = content.replaceAll('const Color(0xFFFDF2F8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFDF2F8))');
  content = content.replaceAll('Color(0xFFFDF2F8)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFDF2F8))');
  
  // Fix bright amber backgrounds
  content = content.replaceAll('const Color(0xFFFFFBEB)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))');
  content = content.replaceAll('Color(0xFFFFFBEB)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))');
  
  // Fix light amber borders
  content = content.replaceAll('const Color(0xFFFEF3C7)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))');
  content = content.replaceAll('Color(0xFFFEF3C7)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))');

  // Fix bright red backgrounds
  content = content.replaceAll('const Color(0xFFFEF2F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFEF2F2))');
  content = content.replaceAll('Color(0xFFFEF2F2)', '(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFEF2F2))');

  // Also replace 'backgroundColor: Colors.white' and 'color: Colors.white' (circle buttons at the top)
  content = content.replaceAll('backgroundColor: Colors.white', 'backgroundColor: Theme.of(context).cardColor');
  content = content.replaceAll('color: Colors.white,', 'color: Theme.of(context).cardColor,');
  content = content.replaceAll('color: Colors.white)', 'color: Theme.of(context).cardColor)');

  // Also fix "Delivery Address" dark blue text if it exists (usually it's AppColors.primary or something similar)
  // We'll leave the delivery address text color for now unless we know exactly what it is. The screenshot shows it's a dark blue.
  // We will check that later.

  file.writeAsStringSync(content);
  print('Fixed more dark mode colors in order_detail_screen.dart');
}
