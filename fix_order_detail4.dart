import 'dart:io';

void main() {
  final path = 'd:\\my_shop\\lib\\features\\orders\\presentation\\screens\\order_detail_screen.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  
  List<String> lines = file.readAsLinesSync();
  bool modified = false;

  for (int i = 0; i < lines.length; i++) {
    // 1. Fix line 1658-1661 const BoxDecoration
    if (lines[i].contains('decoration: const BoxDecoration(')) {
      lines[i] = lines[i].replaceAll('decoration: const BoxDecoration(', 'decoration: BoxDecoration(');
      modified = true;
    }
    
    // 2. Fix color: Colors.white when it's a background
    if (lines[i].contains('color: Colors.white,')) {
      // Check if it's likely a background (not in TextStyle/GoogleFonts/Icon)
      if (!lines[i].contains('style:') && 
          !lines[i].contains('Icon(') && 
          !lines[i].contains('TextStyle') &&
          !lines[i].contains('GoogleFonts')) {
        
        lines[i] = lines[i].replaceAll('color: Colors.white,', 'color: Theme.of(context).cardColor,');
        modified = true;
      }
    }
    
    if (lines[i].contains('color: Colors.white)') || lines[i].contains('color: Colors.white )')) {
      // Sometimes used as color: Colors.white) in BoxDecoration
      if (!lines[i].contains('Icon') && !lines[i].contains('style')) {
        lines[i] = lines[i].replaceAll('color: Colors.white', 'color: Theme.of(context).cardColor');
        modified = true;
      }
    }
    
    // Fix remaining const Color(0xFFF1F5F9) used as background
    if (lines[i].contains('color: const Color(0xFFF1F5F9),')) {
      lines[i] = lines[i].replaceAll('color: const Color(0xFFF1F5F9),', 'color: Theme.of(context).cardColor,');
      modified = true;
    }
  }

  if (modified) {
    file.writeAsStringSync(lines.join('\n') + '\n');
    print('Fixed backgrounds in order_detail_screen.dart');
  } else {
    print('No changes needed');
  }
}
