import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/notifications/presentation/screens/notification_page.dart';

class NotificationBadgeIcon extends StatefulWidget {
  final Color color;
  const NotificationBadgeIcon({super.key, this.color = const Color(0xFF1E293B)});

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  StreamSubscription? _socketSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _setupListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _notificationRepository.getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  void _setupListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((_) {
      _fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            );
            if (refreshed == true) {
              _fetchUnreadCount();
            }
          },
          icon: Icon(PhosphorIconsRegular.bell, color: widget.color, size: 26),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFED3A72),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
