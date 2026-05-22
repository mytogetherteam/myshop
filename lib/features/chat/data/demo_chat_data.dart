import 'package:my_shop/features/chat/data/models/chat_model.dart';

class DemoChatData {
  static final List<ChatConversation> conversations = [
    ChatConversation(
      id: 'conv_1',
      name: 'Aung Kyaw',
      lastMessage: 'Is my order ready for pickup?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      unreadCount: 2,
      isOnline: true,
    ),
    ChatConversation(
      id: 'conv_2',
      name: 'Thida Win',
      lastMessage: 'Thank you so much! The food was delicious 😋',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 0,
      isOnline: true,
    ),
    ChatConversation(
      id: 'conv_3',
      name: 'Zaw Min Htun',
      lastMessage: 'Can I change my delivery address?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 1,
      isOnline: false,
    ),
    ChatConversation(
      id: 'conv_4',
      name: 'Su Su Hlaing',
      lastMessage: 'Do you have any vegetarian options?',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      isOnline: false,
    ),
    ChatConversation(
      id: 'conv_5',
      name: 'Myo Thant',
      lastMessage: 'I placed order #1042. How long will it take?',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 0,
      isOnline: true,
    ),
    ChatConversation(
      id: 'conv_6',
      name: 'Hnin Wai',
      lastMessage: 'Got it, thanks!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  static final Map<String, List<ChatMessage>> messages = {
    'conv_1': [
      ChatMessage(
        id: 'msg_1_1',
        senderId: 'customer_1',
        text: 'Hi, I placed an order 20 minutes ago.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_1_2',
        senderId: 'shop',
        text: 'Hello! Yes, we received your order. It\'s being prepared now.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_1_3',
        senderId: 'customer_1',
        text: 'Great! About how long until it\'s done?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_1_4',
        senderId: 'shop',
        text: 'Should be ready in about 10 more minutes 🙂',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_1_5',
        senderId: 'customer_1',
        text: 'Is my order ready for pickup?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isMe: false,
      ),
    ],
    'conv_2': [
      ChatMessage(
        id: 'msg_2_1',
        senderId: 'customer_2',
        text: 'Hello! I just received my delivery.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_2_2',
        senderId: 'shop',
        text: 'Wonderful! We hope you enjoy it. Let us know if everything is good!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_2_3',
        senderId: 'customer_2',
        text: 'Thank you so much! The food was delicious 😋',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isMe: false,
      ),
    ],
    'conv_3': [
      ChatMessage(
        id: 'msg_3_1',
        senderId: 'customer_3',
        text: 'Hi, I made a mistake with my delivery address.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_3_2',
        senderId: 'shop',
        text: 'No worries! What\'s the correct address?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_3_3',
        senderId: 'customer_3',
        text: 'Can I change my delivery address?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: false,
      ),
    ],
    'conv_4': [
      ChatMessage(
        id: 'msg_4_1',
        senderId: 'customer_4',
        text: 'Hi! I\'m looking at your menu.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_4_2',
        senderId: 'shop',
        text: 'Welcome! Feel free to ask any questions about our menu.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 25)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_4_3',
        senderId: 'customer_4',
        text: 'Do you have any vegetarian options?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isMe: false,
      ),
    ],
    'conv_5': [
      ChatMessage(
        id: 'msg_5_1',
        senderId: 'customer_5',
        text: 'Hey, just placed order #1042.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_5_2',
        senderId: 'shop',
        text: 'Got it! We\'ll start preparing it right away.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 25)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_5_3',
        senderId: 'customer_5',
        text: 'I placed order #1042. How long will it take?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isMe: false,
      ),
    ],
    'conv_6': [
      ChatMessage(
        id: 'msg_6_1',
        senderId: 'shop',
        text: 'Your order has been delivered. Thank you for ordering!',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_6_2',
        senderId: 'customer_6',
        text: 'Got it, thanks!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isMe: false,
      ),
    ],
  };
}
