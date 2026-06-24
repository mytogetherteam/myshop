import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/notifications/presentation/screens/notification_page.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class NotificationBadgeIcon extends StatefulWidget {
  final Color? color;
  const NotificationBadgeIcon({super.key, this.color});

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  StreamSubscription? _socketSubscription;

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
    await _notificationRepository.getUnreadCount();
  }

  void _setupListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((_) {
      _fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _notificationRepository.unreadCount,
      builder: (context, unreadCount, _) {
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
              icon: Icon(PhosphorIconsRegular.bell, color: widget.color ?? Theme.of(context).iconTheme.color, size: 26),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
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
      },
    );
  }
}
