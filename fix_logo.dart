import 'dart:io';

void main() {
  final files = [
    'd:\\my_shop\\lib\\features\\profile\\presentation\\screens\\edit_shop_profile_page.dart',
    'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart',
    'd:\\my_shop\\lib\\features\\main_navigation\\presentation\\screens\\main_navigation_screen.dart',
    'd:\\my_shop\\lib\\core\\presentation\\widgets\\app_bar_title_with_logo.dart',
    'd:\\my_shop\\lib\\core\\presentation\\widgets\\app_logo.dart',
    'd:\\my_shop\\lib\\core\\presentation\\widgets\\app_dialog.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    String content = file.readAsStringSync();
    if (content.contains('assets/images/app_logo.png')) {
      content = content.replaceAll('assets/images/app_logo.png', 'assets/images/app_logo2.png');
      file.writeAsStringSync(content);
      print('Updated \$path');
    }
  }
}
