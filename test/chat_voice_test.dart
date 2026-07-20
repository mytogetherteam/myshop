import 'package:flutter_test/flutter_test.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/data/services/chat_voice_player.dart';

void main() {
  group('ChatMessage voice parsing', () {
    test('parses VOICE attachments and duration', () {
      final message = ChatMessage.fromJson({
        'id': 42,
        'conversationId': 7,
        'senderType': 'SHOP',
        'type': 'VOICE',
        'content': null,
        'isRead': false,
        'isDeleted': false,
        'createdAt': '2026-07-17T10:00:00.000Z',
        'attachments': [
          {
            'id': 9,
            'type': 'VOICE',
            'url': 'https://cdn.example.com/chat/voice.m4a',
            'mimeType': 'audio/mp4',
            'fileSize': 12345,
            'duration': 8,
            'sortOrder': 0,
          },
        ],
      });

      expect(message.kind, ChatMessageKind.voice);
      expect(message.isMe, isTrue);
      expect(message.isVoice, isTrue);
      expect(message.voiceUrl, 'https://cdn.example.com/chat/voice.m4a');
      expect(message.voiceDurationSeconds, 8);
    });

    test('preview shows voice label', () {
      expect(
        ChatConversation.previewFor({
          'type': 'VOICE',
          'isDeleted': false,
        }),
        '🎤 Voice message',
      );
    });
  });

  group('voice playback speed', () {
    test('cycles and formats', () {
      expect(nextVoicePlaybackSpeed(1.0), 1.5);
      expect(nextVoicePlaybackSpeed(1.5), 2.0);
      expect(nextVoicePlaybackSpeed(2.0), 1.0);
      expect(formatVoicePlaybackSpeed(2.0), '2x');
      expect(formatVoiceDuration(const Duration(seconds: 5)), '00:05');
    });
  });
}
