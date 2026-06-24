import 'dart:io';

void main() {
  final path = 'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  
  String content = file.readAsStringSync();

  // Scaffolds & AppBars
  content = content.replaceAll('backgroundColor: Colors.white,', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor,');
  
  // Text fields fill colors
  content = content.replaceAll('fillColor: Colors.white,', 'fillColor: Theme.of(context).cardColor,');
  
  // 0xFFF8FAFC (very light background) -> Theme card color
  content = content.replaceAll('color: const Color(0xFFF8FAFC),', 'color: Theme.of(context).cardColor,');
  content = content.replaceAll('fillColor: const Color(0xFFF8FAFC),', 'fillColor: Theme.of(context).cardColor,');

  // 0xFFE2E8F0 (light border color) -> Theme divider color
  content = content.replaceAll('const BorderSide(color: Color(0xFFE2E8F0))', 'BorderSide(color: Theme.of(context).dividerColor)');
  content = content.replaceAll('borderSide: const BorderSide(color: Color(0xFFE2E8F0)),', 'borderSide: BorderSide(color: Theme.of(context).dividerColor),');
  content = content.replaceAll('border: Border.all(color: const Color(0xFFE2E8F0)),', 'border: Border.all(color: Theme.of(context).dividerColor),');
  content = content.replaceAll('bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),', 'bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),');
  content = content.replaceAll('const BorderSide(color: Color(0xFFE2E8F0), width: 1)', 'BorderSide(color: Theme.of(context).dividerColor, width: 1)');
  
  content = content.replaceAll(': const Color(0xFFE2E8F0),', ': Theme.of(context).dividerColor,');
  
  // Re-restore known text colors that need to be white when selected (from lines 3372, 3400 where they might have been touched, but wait we didn't touch those here).
  // The only thing we replaced above are specific whole lines/assignments.

  file.writeAsStringSync(content);
  print('Fixed remaining white and light backgrounds in order_detail_screen.dart');
}
