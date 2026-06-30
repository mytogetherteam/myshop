import 'dart:io';

void main() {
  final filesToFix = [
    'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart',
  ];

  for (final path in filesToFix) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    final lines = file.readAsLinesSync();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('backgroundColor: Colors.white,')) {
        lines[i] = line.replaceAll('Colors.white', 'Theme.of(context).cardColor');
      }
    }
    
    file.writeAsStringSync('${lines.join('\n')}\n');
    print('Fixed modal colors in \$path');
  }
}
