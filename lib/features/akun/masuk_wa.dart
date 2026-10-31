import 'dart:async';

import 'package:dio/dio.dart' show Options;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Jalur masuk yang tersedia (PRD §7.1, K-112): `wa` = verifikasi WhatsApp balik, `otp` = kode OTP. Gagal memuat = OTP,
/// jalur yang selalu ada sebelum verifikasi balik aktif.
final jalurMasukProvider = FutureProvider.autoDispose<({bool wa, bool otp})>((
  ref,
) async {
  try {
    final j = await ref.watch(apiClientProvider).get('/auth/jalur') as Json;
    return (wa: j['wa'] == true, otp: j['otp'] == true);
  } on ApiException {
    return (wa: false, otp: true);
  }
});

/// Masuk lewat WhatsApp balik: pengguna mengirim kode ke nomor Pramu, tanpa mengetik nomor dan tanpa biaya OTP.
/// Alur: buat tantangan → buka WhatsApp → tunggu pesan masuk → tampilkan nomor tersamar → Lanjut (membuat sesi).
class MasukWaPanel extends ConsumerStatefulWidget {
  const MasukWaPanel({
    super.key,
    required this.namaPerangkat,
    required this.onMasuk,
    this.onPakaiOtp,
    this.intervalPeriksa = const Duration(seconds: 3),
  });

  final String namaPerangkat;
  final Future<void> Function(String token, Json akun) onMasuk;

  /// Null bila OTP tidak tersedia.
  final VoidCallback? onPakaiOtp;
  final Duration intervalPeriksa;

  @override
  ConsumerState<MasukWaPanel> createState() => _MasukWaPanelState();
}

class _MasukWaPanelState extends ConsumerState<MasukWaPanel> {
  Json? _tantangan;
  String _status = 'MULAI';
  String? _tersamar;
  bool _proses = false;
  String? _galat;
  Timer? _timer;
  final _nomorUji = TextEditingController(text: '6281200000001');

  @override
  void dispose() {
    _timer?.cancel();
    _nomorUji.dispose();
    super.dispose();
  }

  Options get _token =>
      Options(headers: {'X-Tantangan-Token': _tantangan!['token'] as String});

  Future<void> _jalankan(Future<void> Function() fn) async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await fn();
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _mulai() => _jalankan(() async {
    final t =
        await ref
                .read(apiClientProvider)
                .post(
                  '/auth/wa/tantangan',
                  data: {'nama_perangkat': widget.namaPerangkat},
                )
            as Json;
    _timer?.cancel();
    _timer = Timer.periodic(widget.intervalPeriksa, (_) => _periksa());
    if (mounted) {
      setState(() {
        _tantangan = t;
        _status = 'MENUNGGU';
        _tersamar = null;
      });
    }
  });

  Future<void> _periksa() async {
    if (_tantangan == null || !mounted) return;
    try {
      final s =
          await ref
                  .read(apiClientProvider)
                  .get(
                    '/auth/wa/tantangan/${_tantangan!['id']}',
                    headers: {
                      'X-Tantangan-Token': _tantangan!['token'] as String,
                    },
                  )
              as Json;
      if (!mounted) return;
      setState(() {
        _status = s['status'] as String;
        _tersamar = s['telepon_tersamar'] as String?;
      });
      if (_status != 'MENUNGGU') _timer?.cancel();
    } on ApiException {
      // Gangguan sesaat: coba lagi pada putaran berikutnya.
    }
  }

  Future<void> _bukaWhatsApp() async {
    final ok = await openWhatsAppUrl(
      ref.read(urlLauncherProvider),
      _tantangan!['tautan_wa'] as String,
    );
    if (!ok && mounted) {
      setState(
        () => _galat =
            'WhatsApp tidak bisa dibuka. Kirim kode ini secara manual ke ${_tantangan!['nomor_pramu']}.',
      );
    }
  }

  Future<void> _lanjut() => _jalankan(() async {
    final res =
        await ref
                .read(apiClientProvider)
                .post(
                  '/auth/wa/tantangan/${_tantangan!['id']}/lanjut',
                  data: {'nama_perangkat': widget.namaPerangkat},
                  options: _token,
                )
            as Json;
    await widget.onMasuk(res['token'] as String, res['akun'] as Json);
  });

  // Hanya mode debug: meniru pesan yang dikirim pengguna lewat jalur webhook yang sama (server menolaknya di produksi).
  Future<void> _simulasi() => _jalankan(() async {
    await ref
        .read(apiClientProvider)
        .post(
          '/dev/wa/kirim',
          data: {'kode': _tantangan!['kode'], 'dari': _nomorUji.text},
        );
    await _periksa();
  });

  void _ulang() {
    _timer?.cancel();
    setState(() {
      _tantangan = null;
      _status = 'MULAI';
      _tersamar = null;
      _galat = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...switch (_status) {
          'MENUNGGU' => _menunggu(context),
          'DITERIMA' => _diterima(context),
          'KEDALUWARSA' || 'DIPAKAI' => _kedaluwarsa(context),
          _ => _mulaiLayar(context),
        },
        if (_galat != null) ...[
          const SizedBox(height: AppSpace.s12),
          FieldErrorText(_galat!),
        ],
        if (widget.onPakaiOtp != null) ...[
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Pakai kode OTP saja',
            variant: AppButtonVariant.text,
            onPressed: _proses
                ? null
                : () {
                    _timer?.cancel();
                    widget.onPakaiOtp!();
                  },
          ),
        ],
      ],
    );
  }

  List<Widget> _mulaiLayar(BuildContext context) => [
    Text(
      'Masuk tanpa mengetik nomor: kirim satu pesan WhatsApp ke Pramu, gratis. Nomor baru otomatis didaftarkan.',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s24),
    AppButton(
      label: 'Masuk lewat WhatsApp',
      loading: _proses,
      expand: true,
      onPressed: _proses ? null : _mulai,
    ),
  ];

  List<Widget> _menunggu(BuildContext context) => [
    Text(
      'Buka WhatsApp dan kirim pesan berisi kode ini ke Pramu. Jangan ubah isinya.',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s12),
    AppCard(
      child: Center(
        child: Text(
          _tantangan!['kode'] as String,
          style: context.text.h1,
          semanticsLabel: 'Kode masuk ${_tantangan!['kode']}',
        ),
      ),
    ),
    const SizedBox(height: AppSpace.s12),
    AppButton(label: 'Buka WhatsApp', expand: true, onPressed: _bukaWhatsApp),
    const SizedBox(height: AppSpace.s8),
    Text('Menunggu pesanmu masuk…', style: context.text.caption),
    if (kDebugMode) ...[
      const SizedBox(height: AppSpace.s12),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hanya mode debug: tiru pesan yang dikirim pengguna.',
              style: context.text.caption,
            ),
            TextField(
              controller: _nomorUji,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor uji'),
            ),
            const SizedBox(height: AppSpace.s8),
            AppButton(
              label: 'Simulasikan pesan masuk',
              variant: AppButtonVariant.secondary,
              onPressed: _proses ? null : _simulasi,
            ),
          ],
        ),
      ),
    ],
    AppButton(
      label: 'Batal',
      variant: AppButtonVariant.text,
      onPressed: _ulang,
    ),
  ];

  List<Widget> _diterima(BuildContext context) => [
    Text(
      'Nomor $_tersamar terbaca. Lanjut masuk dengan nomor ini?',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s24),
    AppButton(
      label: 'Ya, lanjut',
      loading: _proses,
      expand: true,
      onPressed: _proses ? null : _lanjut,
    ),
    AppButton(
      label: 'Bukan nomor saya',
      variant: AppButtonVariant.text,
      onPressed: _proses ? null : _ulang,
    ),
  ];

  List<Widget> _kedaluwarsa(BuildContext context) => [
    Text(
      'Kode sudah kedaluwarsa. Buat kode baru untuk mencoba lagi.',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s24),
    AppButton(
      label: 'Buat kode baru',
      loading: _proses,
      expand: true,
      onPressed: _proses ? null : _mulai,
    ),
  ];
}
