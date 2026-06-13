import 'package:flutter/material.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/presentation/screens/chat_detail_screen.dart';

/// Opens [ChatDetailScreen] with duplicate-push protection.
class ChatNavigation {
  ChatNavigation._();

  static bool _isOpening = false;

  static String routeNameFor(ChatConversation conversation) {
    if (conversation.id > 0) return 'chat_detail_${conversation.id}';
    return 'chat_detail_order_${conversation.orderId}';
  }

  static Future<void> open(
    BuildContext context,
    ChatConversation conversation,
  ) async {
    if (_isOpening) return;

    final routeName = routeNameFor(conversation);
    if (ModalRoute.of(context)?.settings.name == routeName) return;

    _isOpening = true;
    try {
      await Navigator.push(
        context,
        PageRouteBuilder(
          settings: RouteSettings(name: routeName),
          pageBuilder: (context, animation, secondaryAnimation) =>
              ChatDetailScreen(conversation: conversation),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;
            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } finally {
      _isOpening = false;
    }
  }
}
