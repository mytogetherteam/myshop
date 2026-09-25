import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/features/call/data/shop_call_session.dart';

const _kBgTop    = Color(0xFFED3973); // app primary pink
const _kBgBottom = Color(0xFF0D060A); // near-black at bottom
const _kDeclineRed = Color(0xFFE41E3F);

/// Messenger-style active call screen for Shop app.
class ActiveCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerImageUrl;
  const ActiveCallScreen({super.key, required this.callerName, this.callerImageUrl});

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

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_call.state.value != ShopCallState.connected) return false;
      setState(() => _elapsed = DateTime.now().difference(_connectedAt));
      return true;
    });

    _call.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_call.state.value == ShopCallState.idle && mounted) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _call.state.removeListener(_onStateChanged);
    super.dispose();
  }

  String _formatElapsed() {
    final mins = _elapsed.inMinutes.toString().padLeft(2, '0');
    final secs = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _kBgTop,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kBgBottom,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBgBottom,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary, _kBgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.38, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 44),
                Text(
                  widget.callerName,
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.w700, letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voice Call',
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.72), fontSize: 13),
                ),
                const Spacer(flex: 1),
                // Avatar
                Container(
                  width: 148, height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 3),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 44, spreadRadius: 10)],
                  ),
                  child: ClipOval(
                    child: (widget.callerImageUrl != null && widget.callerImageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: widget.callerImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(
                              child: Text(
                                widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ),
                const Spacer(flex: 1),
                // Timer
                Text(
                  _formatElapsed(),
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w600, letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 52),
                // Controls row: Mute | End | Speaker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _call.isMuted,
                      builder: (_, muted, _) => _circleBtn(
                        icon: muted ? PhosphorIcons.microphoneSlash : PhosphorIcons.microphone,
                        label: muted ? 'Unmute' : 'Mute',
                        active: muted,
                        onTap: _call.toggleMute,
                      ),
                    ),
                    // End call
                    GestureDetector(
                      onTap: () async {
                        await _call.endCall();
                        if (context.mounted && Navigator.canPop(context)) Navigator.of(context).pop();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 74, height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kDeclineRed,
                              boxShadow: [BoxShadow(color: _kDeclineRed.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 2, offset: const Offset(0, 6))],
                            ),
                            child: const Icon(PhosphorIcons.phoneSlash, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 8),
                          Text('End Call', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _call.isSpeakerOn,
                      builder: (_, speaker, _) => _circleBtn(
                        icon: speaker ? PhosphorIcons.speakerHigh : PhosphorIcons.speakerNone,
                        label: 'Speaker',
                        active: speaker,
                        onTap: _call.toggleSpeaker,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: active ? 0 : 0.28), width: 1.5),
            ),
            child: Icon(icon, color: active ? AppColors.primary : Colors.white, size: 25),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.72), fontSize: 12)),
        ],
      ),
    );
  }
}




