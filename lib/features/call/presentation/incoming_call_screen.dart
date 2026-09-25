import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/features/call/data/shop_call_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/features/call/presentation/active_call_screen.dart';
import 'package:audioplayers/audioplayers.dart';

const _kBgTop    = Color(0xFFED3973); // app primary pink
const _kBgBottom = Color(0xFF0D060A); // near-black at bottom
const _kAcceptGreen = Color(0xFF00C875);
const _kDeclineRed  = Color(0xFFE41E3F);

/// Messenger-style incoming call screen for Shop app.
class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerImageUrl;
  final String callId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerImageUrl,
    required this.callId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final _session = ShopCallSession();
  final AudioPlayer _ringPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _session.state.addListener(_onStateChanged);
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    await _ringPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringPlayer.play(AssetSource('alert/ringtone.mp3'));
  }

  void _onStateChanged() {
    if (_session.state.value == ShopCallState.idle && mounted) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _ringPlayer.stop();
    _ringPlayer.dispose();
    _session.state.removeListener(_onStateChanged);
    super.dispose();
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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        widget.callerName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Voice Call',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                _PulsingAvatar(name: widget.callerName, imageUrl: widget.callerImageUrl),
                const Spacer(flex: 3),
                Text(
                  'Incoming call',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 52),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CallActionButton(
                        icon: PhosphorIcons.phoneX,
                        label: 'Decline',
                        color: _kDeclineRed,
                        onTap: () async {
                          await _session.rejectCall();
                        },
                      ),
                      _CallActionButton(
                        icon: PhosphorIcons.phoneCall,
                        label: 'Accept',
                        color: _kAcceptGreen,
                        onTap: () async {
                          await _session.acceptCall();
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => ActiveCallScreen(
                                  callerName: widget.callerName,
                                  callerImageUrl: widget.callerImageUrl,
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
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  final String name;
  final String? imageUrl;
  const _PulsingAvatar({required this.name, this.imageUrl});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale1, _scale2, _scale3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _scale1 = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scale2 = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)));
    _scale3 = Tween<double>(begin: 1.0, end: 2.25).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _ring(Animation<double> anim, double maxOpacity) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final t = ((anim.value - 1.0) / 1.25).clamp(0.0, 1.0);
        return Transform.scale(
          scale: anim.value,
          child: Container(
            width: 148, height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: maxOpacity * (1.0 - t)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270, height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(_scale3, 0.07),
          _ring(_scale2, 0.13),
          _ring(_scale1, 0.22),
          Container(
            width: 148, height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 3),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 44, spreadRadius: 10)],
            ),
            child: ClipOval(
              child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ),
        ],
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
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 2, offset: const Offset(0, 6))],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}




