import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/call/data/shop_call_session.dart';
import 'package:my_shop/features/call/presentation/active_call_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'dart:async';

const _kBgTop    = Color(0xFFED3973); // app primary pink
const _kBgBottom = Color(0xFF0D060A); // near-black at bottom
const _kDeclineRed  = Color(0xFFE41E3F);

/// Messenger-style outgoing call screen for Shop app.
class OutgoingCallScreen extends StatefulWidget {
  final String customerName;
  final String? customerImageUrl;

  const OutgoingCallScreen({super.key, required this.customerName, this.customerImageUrl});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  final _session = ShopCallSession();
  late final AnimationController _pulseController;
  late final Animation<double> _ring1, _ring2, _ring3;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ring1 = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 1.0, end: 2.25).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _session.onOutgoingCallAccepted = (callId, name, imageUrl) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ActiveCallScreen(callerName: name, callerImageUrl: imageUrl)),
      );
    };

    _session.onOutgoingCallEnded = () {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    };

    _session.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_session.state.value == ShopCallState.idle && mounted) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _session.state.removeListener(_onStateChanged);
    _session.onOutgoingCallAccepted = null;
    _session.onOutgoingCallEnded = null;
    super.dispose();
  }

  Future<void> _hangUp() async {
    await _session.endCall();
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Widget _buildRing(Animation<double> anim, double maxOpacity) {
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
                const SizedBox(height: 40),
                Text(
                  widget.customerName,
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voice Call',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.72)),
                ),
                const Spacer(flex: 1),
                SizedBox(
                  width: 270, height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRing(_ring3, 0.07),
                      _buildRing(_ring2, 0.13),
                      _buildRing(_ring1, 0.22),
                      Container(
                        width: 148, height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 3),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 44, spreadRadius: 10)],
                        ),
                        child: ClipOval(
                          child: (widget.customerImageUrl != null && widget.customerImageUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: widget.customerImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: Text(
                                      widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : 'C',
                                      style: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Center(
                                    child: Text(
                                      widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : 'C',
                                      style: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : 'C',
                                    style: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                _CallingText(),
                const SizedBox(height: 44),
                GestureDetector(
                  onTap: _hangUp,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kDeclineRed,
                          boxShadow: [BoxShadow(color: _kDeclineRed.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 2, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(PhosphorIcons.phoneX, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
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

class _CallingText extends StatefulWidget {
  @override
  State<_CallingText> createState() => _CallingTextState();
}

class _CallingTextState extends State<_CallingText> {
  int _dotCount = 1;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Calling${'.' * _dotCount}',
      style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withValues(alpha: 0.78)),
    );
  }
}





