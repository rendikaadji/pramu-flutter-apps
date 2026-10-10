import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';

const _channel = MethodChannel('pramu/platform');

/// Jembatan native kecil: FLAG_SECURE (Android) dan buka pengaturan aplikasi.
/// Semua panggilan aman bila channel tidak ada (test, iOS, desktop).
abstract final class PlatformBridge {
  static int _secure = 0;

  static Future<void> _setSecure(bool on) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } on MissingPluginException {
      // platform tanpa implementasi
    } on PlatformException {
      // abaikan
    }
  }

  /// Hitung referensi: layar bertumpuk tidak saling mematikan flag.
  static Future<void> secureOn() async {
    if (_secure++ == 0) await _setSecure(true);
  }

  static Future<void> secureOff() async {
    if (_secure > 0 && --_secure == 0) await _setSecure(false);
  }

  /// Android: pengaturan aplikasi lewat channel. false bila tak didukung (iOS: pakai `app-settings:`).
  static Future<bool> openAppSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// Bungkus layar sensitif (KTP, selfie, SKCK, rekening): FLAG_SECURE selama tampil, dan isi
/// diburamkan saat app `inactive` (app switcher iOS / panel sistem) - MOB-SEC-09.
class SecureScreenGuard extends StatefulWidget {
  const SecureScreenGuard({super.key, required this.child});
  final Widget child;

  @override
  State<SecureScreenGuard> createState() => _SecureScreenGuardState();
}

class _SecureScreenGuardState extends State<SecureScreenGuard>
    with WidgetsBindingObserver {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PlatformBridge.secureOn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlatformBridge.secureOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final hide = state != AppLifecycleState.resumed;
    if (hide != _hidden) setState(() => _hidden = hide);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_hidden)
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: ColoredBox(
                color: context.tokens.canvas,
                child: Center(
                  child: Icon(
                    LucideIcons.lock,
                    size: 48,
                    color: context.tokens.textSubtle,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
