import 'dart:io';

void main() {
  final filesToFix = [
    'd:\\my_shop\\lib\\features\\reports\\presentation\\screens\\top_selling_items_screen.dart',
    'd:\\my_shop\\lib\\features\\reports\\presentation\\screens\\report_page.dart',
    'd:\\my_shop\\lib\\features\\reports\\presentation\\screens\\analytics_page.dart',
    'd:\\my_shop\\lib\\features\\profile\\presentation\\screens\\edit_shop_profile_page.dart',
    'd:\\my_shop\\lib\\features\\profile\\presentation\\screens\\edit_payment_page.dart',
    'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart',
    'd:\\my_shop\\lib\\features\\menu\\presentation\\screens\\add_new_item_screen.dart',
    'd:\\my_shop\\lib\\features\\chat\\presentation\\screens\\chat_detail_screen.dart',
    'd:\\my_shop\\lib\\features\\auth\\presentation\\screens\\register_page.dart',
    'd:\\my_shop\\lib\\core\\presentation\\widgets\\image_picker_widget.dart',
  ];

  for (final path in filesToFix) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    final lines = file.readAsLinesSync();
    bool insideBottomSheet = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('showModalBottomSheet')) {
        insideBottomSheet = true;
      }
      
      if (insideBottomSheet && line.contains('backgroundColor: Colors.white')) {
        lines[i] = line.replaceAll('Colors.white', 'Theme.of(context).cardColor');
      }
      
      // basic heuristic to exit
      if (insideBottomSheet && line.contains('builder:')) {
        insideBottomSheet = false;
      }
    }
    
    file.writeAsStringSync(lines.join('\n') + '\n');
    print('Fixed modal colors in \$path');
  }
}
