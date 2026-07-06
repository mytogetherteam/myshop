import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:my_shop/core/data/services/storage_service.dart';

/// Shows a bottom-sheet that walks the owner through phone-specific
/// settings required to keep the app alive for order notifications.
///
/// Call after first login or from Settings:
///   PhoneSetupGuideSheet.show(context);
class PhoneSetupGuideSheet extends StatelessWidget {
  const PhoneSetupGuideSheet._();

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return;
    final hasSeen = await StorageService.instance.isPhoneSetupGuideSeen();
    if (!hasSeen && context.mounted) {
      await show(context);
    }
  }

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const PhoneSetupGuideSheet._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _SetupGuideBody(scrollController: ScrollController()),
        ),
      ),
    );
  }
}

class _SetupGuideBody extends StatefulWidget {
  final ScrollController scrollController;
  const _SetupGuideBody({required this.scrollController});
  @override
  State<_SetupGuideBody> createState() => _SetupGuideBodyState();
}

class _SetupGuideBodyState extends State<_SetupGuideBody> with WidgetsBindingObserver {
  String _brand = 'generic';
  bool _batteryOptIgnored = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectBrand();
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    final notification = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _batteryOptIgnored = battery;
        _notificationGranted = notification;
      });
    }
  }

  Future<void> _detectBrand() async {
    if (!Platform.isAndroid) return;
    final info = await DeviceInfoPlugin().androidInfo;
    final m = info.manufacturer.toLowerCase();
    String brand = 'generic';
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      brand = 'xiaomi';
    } else if (m.contains('oppo') || m.contains('realme') || m.contains('oneplus')) {
      brand = 'oppo';
    } else if (m.contains('vivo')) {
      brand = 'vivo';
    } else if (m.contains('huawei') || m.contains('honor')) {
      brand = 'huawei';
    } else if (m.contains('samsung')) {
      brand = 'samsung';
    }
    if (mounted) setState(() => _brand = brand);
  }

  Future<void> _requestBatteryOptimization() async {
    await Permission.ignoreBatteryOptimizations.request();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4D6D), Color(0xFFFF8E53)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Notification ဖွင့်ပါ',
                      style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'App အပြင်ထွက်ထားချိန်မှာ Order လက်ခံရရှိဖို့ မဖြစ်မနေ လိုအပ်ပါတယ်',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700)),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ဒီ Settings တွေကို မပြင်ထားရင် Order အသံမြည်မှာ မဟုတ်တဲ့အတွက် Order လွတ်သွားနိုင်ပါတယ်!',
                  style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFF856404),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 1, icon: '🔋',
          title: 'Battery Optimization ပိတ်ပါ',
          subtitle: 'အောက်ပါ ခလုတ်ကို နှိပ်ပြီး ခွင့်ပြု (Allow) ပေးပါ',
          action: SizedBox(
            width: double.infinity,
            child: _batteryOptIgnored
                ? Text(
                    '✅ ပြီးပါပြီ',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600),
                  )
                : ElevatedButton(
                    onPressed: _requestBatteryOptimization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Allow Battery Optimization',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        _BrandSpecificStep(brand: _brand),
        const SizedBox(height: 14),
        _StepCard(
          step: 3, icon: '🔔',
          title: 'Notification ဖွင့်ပါ',
          subtitle: 'Settings ထဲတွင် My Shop ၏ Notification ကို ဖွင့်ထားပါ',
          action: SizedBox(
            width: double.infinity,
            child: _notificationGranted
                ? Text(
                    '✅ ပြီးပါပြီ',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600),
                  )
                : OutlinedButton(
                    onPressed: () => openAppSettings(),
                    child: Text('App Settings ကို ဖွင့်ရန်',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: (_batteryOptIgnored && _notificationGranted)
                  ? const LinearGradient(
                      colors: [Color(0xFFFF4D6D), Color(0xFFFF8E53)],
                    )
                  : null,
              color: (_batteryOptIgnored && _notificationGranted)
                  ? null
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: (_batteryOptIgnored && _notificationGranted)
                  ? () async {
                      await StorageService.instance.setPhoneSetupGuideSeen();
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                '✅ အဆင်ပြေပါပြီ — Order စတင် လက်ခံပါ!',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandSpecificStep extends StatelessWidget {
  final String brand;
  const _BrandSpecificStep({required this.brand});

  @override
  Widget build(BuildContext context) {
    String title = 'Background Activity / AutoStart ဖွင့်ပါ';
    String steps = '၁။ Settings → Apps → My Shop ကိုသွားပါ။\n၂။ Battery / Power settings ကို နှိပ်ပါ။\n၃။ "Unrestricted" သို့မဟုတ် "No restriction" ကို ရွေးပါ။\n၄။ "AutoStart" သို့မဟုတ် "Auto Launch" ရှိပါက ဖွင့် (ON) ပါ။';
    String icon = '📱';
    
    switch (brand) {
      case 'xiaomi':
        title = 'Xiaomi/Redmi: AutoStart ဖွင့်ပါ';
        steps = '၁။ Settings → Apps → Manage Apps ကိုသွားပါ။\n၂။ "My Shop" ကို ရှာပါ။\n၃။ "Autostart" ကို ဖွင့် (ON) ပေးပါ။\n၄။ "Battery Saver" ထဲဝင်ပြီး "No Restrictions" ရွေးပါ။';
        break;
      case 'oppo':
        title = 'OPPO/Realme: Auto Launch ဖွင့်ပါ';
        steps = '၁။ Phone Manager → Privacy Permissions သွားပါ။\n၂။ "My Shop" ကို ရှာပြီး Auto Launch ဖွင့် (ON) ပေးပါ။\n၃။ Settings → Battery → App Battery Management သွားပါ။\n၄။ My Shop → Allow background activity ကို ဖွင့်ပေးပါ။';
        break;
      case 'vivo':
        title = 'Vivo: Background Activity ဖွင့်ပါ';
        steps = '၁။ Settings → Battery ကိုသွားပါ။\n၂။ Background Power Management နှိပ်ပါ။\n၃။ "My Shop" ကို ရှာပြီး Do Not Restrict ရွေးပါ။\n၄။ Settings → Apps → My Shop → Background popup ကို Allow လုပ်ပါ။';
        break;
      case 'huawei':
        title = 'Huawei/Honor: AutoLaunch ဖွင့်ပါ';
        steps = '၁။ Phone Manager → App Launch သွားပါ။\n၂။ "My Shop" ကို ရှာပြီး Auto-manage ကို ပိတ် (OFF) ပါ။\n၃။ Auto-launch, Secondary launch နဲ့ Run in background အကုန် ဖွင့်ပါ။';
        break;
      case 'samsung':
        title = 'Samsung: Unrestricted ရွေးပါ';
        steps = '၁။ Settings → Apps → My Shop → Battery သွားပါ။\n၂။ "Unrestricted" ကို ရွေးပေးပါ။\n၃။ "Put unused apps to sleep" ကို ပိတ် (OFF) ပါ။';
        break;
    }
    
    return _StepCard(
      step: 2, icon: icon,
      title: title,
      subtitle: steps,
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const _StepCard({
    required this.step, required this.icon,
    required this.title, required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E), shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$step',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey[700], height: 1.7),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
