import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../data/shop_call_session.dart';

/// Active call screen shown after the shop accepts a call.
class ActiveCallScreen extends StatefulWidget {
  final String callerName;
  const ActiveCallScreen({super.key, required this.callerName});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final _call = ShopCallSession();
  Duration _elapsed = Duration.zero;
  late DateTime _connectedAt;

  @override
  void initState() {
    super.initState();
    _connectedAt = DateTime.now();

    // Update timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_call.state.value != ShopCallState.connected) return false;
      setState(() => _elapsed = DateTime.now().difference(_connectedAt));
      return true;
    });

    // Auto-dismiss if caller ends
    _call.state.addListener(() {
      if (_call.state.value == ShopCallState.idle && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  String _formatElapsed() {
    final mins = _elapsed.inMinutes.toString().padLeft(2, '0');
    final secs = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF22C55E), width: 2),
              ),
              child: Center(
                child: Text(
                  widget.callerName.isNotEmpty
                      ? widget.callerName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.callerName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatElapsed(),
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute
                ValueListenableBuilder<bool>(
                  valueListenable: _call.isMuted,
                  builder: (_, muted, __) => _controlButton(
                    icon: muted
                        ? PhosphorIcons.microphoneSlash
                        : PhosphorIcons.microphone,
                    label: muted ? 'Unmute' : 'Mute',
                    color: muted ? Colors.white : Colors.white24,
                    iconColor: muted ? Colors.red : Colors.white,
                    onTap: _call.toggleMute,
                  ),
                ),
                // End call
                _controlButton(
                  icon: PhosphorIcons.phoneFill,
                  label: 'End',
                  color: Colors.red,
                  iconColor: Colors.white,
                  size: 68,
                  onTap: () async {
                    await _call.endCall();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                // Spacer
                const SizedBox(width: 56),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: iconColor, size: size * 0.42),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
