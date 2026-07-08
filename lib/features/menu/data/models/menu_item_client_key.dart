/// Stable client-side keys for reorderable menu item form rows.
class MenuItemClientKey {
  static int _counter = 0;

  static String next([String prefix = 'row']) => '$prefix-${++_counter}';

  static String forId(String prefix, int id) => '$prefix-$id';
}
