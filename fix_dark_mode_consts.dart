import 'dart:io';

void main() {
  final dir = Directory('d:\\my_shop\\lib\\features');
  final files = dir.listSync(recursive: true).where((e) => e.path.endsWith('.dart') && e is File).cast<File>();

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll('const Divider(height: 1, color: Theme.of(context).dividerColor)', 'Divider(height: 1, color: Theme.of(context).dividerColor)');
    
    // Fix context in _getCategoryColor inside category_list_screen.dart
    if (file.path.endsWith('category_list_screen.dart')) {
      content = content.replaceAll('Color _getCategoryColor(String? name)', 'Color _getCategoryColor(BuildContext context, String? name)');
      content = content.replaceAll('_getCategoryColor(category.displayName)', '_getCategoryColor(context, category.displayName)');
    }

    // Fix analytics_donut_chart.dart
    if (file.path.endsWith('analytics_donut_chart.dart')) {
      content = content.replaceAll('this.section2Color = (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))),', 'this.section2Color,');
      content = content.replaceAll('final Color section2Color;', 'final Color? section2Color;');
      content = content.replaceAll('color: widget.section2Gradient != null ? null : widget.section2Color,', 'color: widget.section2Gradient != null ? null : (widget.section2Color ?? (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))),');
    }

    // Fix progress_bar_item.dart
    if (file.path.endsWith('progress_bar_item.dart')) {
      content = content.replaceAll('this.backgroundColor = (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))),', 'this.backgroundColor,');
      content = content.replaceAll('final Color backgroundColor;', 'final Color? backgroundColor;');
      content = content.replaceAll('color: widget.backgroundColor,', 'color: widget.backgroundColor ?? (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)),');
    }
    
    // Fix any other const errors globally
    content = content.replaceAll('const (Theme.of(context)', '(Theme.of(context)');
    // Some lines might have const Icon(...) or const Text(...) spanning multiple lines, we can use regex
    content = content.replaceAll(RegExp(r'const\s+Icon\('), 'Icon(');
    content = content.replaceAll(RegExp(r'const\s+Text\('), 'Text(');
    content = content.replaceAll(RegExp(r'const\s+Padding\('), 'Padding(');
    content = content.replaceAll(RegExp(r'const\s+Divider\('), 'Divider(');

    if (content != original) {
      file.writeAsStringSync(content);
    }
  }
}
