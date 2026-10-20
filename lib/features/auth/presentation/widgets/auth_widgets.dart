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
    this.onDone,
  });

  final int seconds;
  final VoidCallback? onDone;
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
      if (_left == 0) widget.onDone?.call();
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

/// Kepala layar auth di atas glow: logo Pramu, judul, penjelasan singkat.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PramuMark(size: 56),
          const SizedBox(height: AppSpace.s16),
          Semantics(header: true, child: Text(title, style: context.text.h1)),
          const SizedBox(height: AppSpace.s4),
          Text(subtitle, style: context.text.body.copyWith(color: t.textMuted)),
        ],
      ),
    );
  }
}

/// Satu baris tautan sekunder di bawah tombol utama: teks prompt + aksi.
class AuthSwitchRow extends StatelessWidget {
  const AuthSwitchRow({super.key, required this.prompt, required this.child});

  final String prompt;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.s8),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: context.text.body.copyWith(color: context.tokens.textMuted),
        ),
        child,
      ],
    ),
  );
}
