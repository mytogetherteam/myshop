import 'package:flutter_test/flutter_test.dart';
import 'package:my_shop/features/chat/data/models/chat_window.dart';

void main() {
  test('completed chat stays writable before four hours', () {
    final completedAt = DateTime.now().subtract(
      const Duration(hours: 4) - const Duration(seconds: 1),
    );

    expect(ChatWindow.isWritable('DELIVERED', completedAt), isTrue);
    expect(ChatWindow.isWritable('PICKED_UP', completedAt), isTrue);
  });

  test('completed chat becomes read-only after four hours', () {
    final completedAt = DateTime.now().subtract(
      const Duration(hours: 4, seconds: 1),
    );

    expect(ChatWindow.isWritable('DELIVERED', completedAt), isFalse);
    expect(ChatWindow.isWritable('PICKED_UP', completedAt), isFalse);
  });

  test('active chat stays writable and canceled chat closes', () {
    final now = DateTime.now();

    expect(ChatWindow.isWritable('COOKING', now), isTrue);
    expect(ChatWindow.isWritable('CANCELED', now), isFalse);
  });
}
