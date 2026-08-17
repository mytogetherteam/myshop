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
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E1B4B), // Indigo 950
              Color(0xFF0F172A), // Slate 900
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              // Avatar
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.callerName.isNotEmpty
                        ? widget.callerName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Name
              Text(
                widget.callerName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Timer
              Text(
                _formatElapsed(),
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              // Controls
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
                      color: muted ? Colors.white : Colors.white.withOpacity(0.15),
                      iconColor: muted ? const Color(0xFFEF4444) : Colors.white,
                      onTap: _call.toggleMute,
                    ),
                  ),
                  // End call
                  _controlButton(
                    icon: PhosphorIcons.phoneSlash,
                    label: 'End Call',
                    color: const Color(0xFFEF4444),
                    iconColor: Colors.white,
                    size: 72,
                    onTap: () async {
                      await _call.endCall();
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  // Speaker
                  ValueListenableBuilder<bool>(
                    valueListenable: _call.isSpeakerOn,
                    builder: (_, speaker, __) => _controlButton(
                      icon: speaker
                          ? PhosphorIcons.speakerHigh
                          : PhosphorIcons.speakerLow,
                      label: speaker ? 'Speaker On' : 'Speaker Off',
                      color: speaker ? Colors.white : Colors.white.withOpacity(0.15),
                      iconColor: speaker ? const Color(0xFF3B82F6) : Colors.white,
                      onTap: () => _call.isSpeakerOn.value = !_call.isSpeakerOn.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
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
