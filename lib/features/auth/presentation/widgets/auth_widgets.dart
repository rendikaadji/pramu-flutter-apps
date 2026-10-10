import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// +6281234567890 -> +6281••••••7890 (digit tengah disamarkan).
String maskPhone(String phone) {
  if (phone.length < 9) return phone;
  final head = phone.substring(0, phone.length - 4);
  return '${head.substring(0, 6)}${'•' * (head.length - 6)}'
      '${phone.substring(phone.length - 4)}';
}

String formatCountdown(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

/// Hitung mundur detik; ganti `key` untuk memulai ulang. Berhenti saat dispose.
class CountdownBuilder extends StatefulWidget {
  const CountdownBuilder({
    super.key,
    required this.seconds,
    required this.builder,
  });

  final int seconds;
  final Widget Function(BuildContext context, int remaining) builder;

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left = _left > 0 ? _left - 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _left);
}

/// Banner offline untuk layar form saat aksi terakhir gagal karena jaringan.
Widget? offlineBannerFor(ApiException? e) =>
    e != null && e.isNetwork ? const OfflineBanner() : null;
