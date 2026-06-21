import 'dart:io';

void main() {
  final files = [
    'd:\\my_shop\\lib\\features\\auth\\presentation\\screens\\login_page.dart',
    'd:\\my_shop\\lib\\features\\auth\\presentation\\screens\\register_page.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    String content = file.readAsStringSync();
    
    // Replace Scaffold and AppBar backgrounds
    content = content.replaceAll('backgroundColor: Colors.white,', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor,');
    
    // Replace text colors
    content = content.replaceAll('color: Colors.black,', 'color: Theme.of(context).textTheme.bodyLarge?.color,');
    content = content.replaceAll('color: Colors.black)', 'color: Theme.of(context).textTheme.bodyLarge?.color)');
    content = content.replaceAll('color: Colors.black87,', 'color: Theme.of(context).textTheme.bodyLarge?.color,');
    content = content.replaceAll('color: Colors.grey[600],', 'color: Theme.of(context).textTheme.bodyMedium?.color,');
    content = content.replaceAll('color: Colors.grey[700],', 'color: Theme.of(context).textTheme.bodyMedium?.color,');
    content = content.replaceAll('color: Colors.black54,', 'color: Theme.of(context).textTheme.bodySmall?.color,');
    
    // Replace borders
    content = content.replaceAll('border: Border.all(color: Colors.grey.shade200),', 'border: Border.all(color: Theme.of(context).dividerColor),');
    content = content.replaceAll('borderSide: BorderSide(color: Colors.grey[200]!, width: 1),', 'borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey[200]!, width: 1),');
    content = content.replaceAll('border: Border(bottom: BorderSide(color: Colors.grey[200]!)),', 'border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),');
    
    // Replace fill color
    content = content.replaceAll('fillColor: Colors.grey[50],', 'fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey[50],');
    
    file.writeAsStringSync(content);
    print('Fixed \$path');
  }
}
