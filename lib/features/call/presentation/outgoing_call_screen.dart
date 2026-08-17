import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/call/data/shop_call_session.dart';
import 'package:my_shop/features/call/presentation/active_call_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Full-screen outgoing call screen shown when the shop calls a customer.
/// Navigates to [ActiveCallScreen] once the user accepts, or pops if rejected/timed out.
class OutgoingCallScreen extends StatefulWidget {
  final String customerName;

  const OutgoingCallScreen({
    super.key,
    required this.customerName,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  final _session = ShopCallSession();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Navigate to active call when user accepts
    _session.onOutgoingCallAccepted = (callId, name) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(callerName: name),
        ),
      );
    };

    // Pop back if user rejected / timed out
    _session.onOutgoingCallEnded = () {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    };

    // Listen to state for CALL_REJECTED / CALL_TIMEOUT coming via state notifier
    _session.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_session.state.value == ShopCallState.idle && mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
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
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
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
              const SizedBox(height: 80),

              // Caller label
              Text(
                'Calling Customer...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),

              // Pulsing avatar
              ScaleTransition(
                scale: _pulseAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Inner ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                    ),
                    // Avatar
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.customerName.isNotEmpty
                              ? widget.customerName[0].toUpperCase()
                              : 'C',
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Customer name
              Text(
                widget.customerName,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Animated "Ringing..." dots
              _RingingText(),

              const Spacer(),

              // Hang up button
              GestureDetector(
                onTap: _hangUp,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    PhosphorIcons.phoneSlash,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Cancel Call',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingingText extends StatefulWidget {
  @override
  State<_RingingText> createState() => _RingingTextState();
}

class _RingingTextState extends State<_RingingText> {
  int _dotCount = 1;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() => _dotCount = (_dotCount % 3) + 1);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ringing${'.' * _dotCount}',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white54,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
