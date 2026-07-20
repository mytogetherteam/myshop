import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../data/shop_call_session.dart';
import 'active_call_screen.dart';

/// Full-screen incoming call screen shown when a user calls the shop.
/// Displayed as a route push from FCM or STOMP CALL_INCOMING event.
class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String callId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Animated avatar
            _PulsingAvatar(name: callerName),
            const SizedBox(height: 24),
            Text(
              callerName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Incoming call from customer...',
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
            ),
            const Spacer(flex: 3),
            // Accept / Reject row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reject
                  _CallActionButton(
                    icon: PhosphorIcons.phoneX,
                    label: 'Decline',
                    color: Colors.red,
                    onTap: () async {
                      await ShopCallSession().rejectCall();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  // Accept
                  _CallActionButton(
                    icon: PhosphorIcons.phoneCall,
                    label: 'Accept',
                    color: const Color(0xFF22C55E),
                    onTap: () async {
                      await ShopCallSession().acceptCall();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ActiveCallScreen(
                            callerName: callerName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  final String name;
  const _PulsingAvatar({required this.name});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
