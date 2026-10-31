import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// S-01 Masuk: nomor WhatsApp lalu kode 6 angka (PRD §7.1). Nomor baru otomatis menjadi akun baru.
class MasukScreen extends ConsumerStatefulWidget {
  const MasukScreen({super.key});

  @override
  ConsumerState<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends ConsumerState<MasukScreen> {
  final _telepon = TextEditingController();
  bool _kodeTerkirim = false;
  bool _proses = false;
  ApiException? _galat;

  @override
  void dispose() {
    _telepon.dispose();
    super.dispose();
  }

  Future<void> _jalankan(Future<void> Function() fn) async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await fn();
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = e);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _kirimKode() => _jalankan(() async {
    await ref
        .read(apiClientProvider)
        .post('/auth/otp', data: {'telepon': _telepon.text});
    if (mounted) setState(() => _kodeTerkirim = true);
  });

  Future<void> _verifikasi(String kode) => _jalankan(() async {
    final res =
        await ref
                .read(apiClientProvider)
                .post(
                  '/auth/otp/verifikasi',
                  data: {
                    'telepon': _telepon.text,
                    'kode': kode,
                    'nama_perangkat': _namaPerangkat(),
                  },
                )
            as Json;
    await ref
        .read(sessionProvider.notifier)
        .masuk(res['token'] as String, res['akun'] as Json);
  });

  // Nama perangkat tampil di daftar perangkat akun (PRD §7.1); cukup sistem operasinya.
  static String _namaPerangkat() => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iPhone',
    final os => os.name,
  };

  @override
  Widget build(BuildContext context) {
    final galatKolom = _galat?.fields;
    final galatUmum = _galat != null && (galatKolom?.isEmpty ?? true)
        ? pesanGalat(_galat!)
        : null;

    return AppScaffold(
      title: 'Masuk',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _kodeTerkirim ? 'Masukkan kode' : 'Masuk ke Pramu',
            style: context.text.h1,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            _kodeTerkirim
                ? 'Kode 6 angka dikirim lewat WhatsApp ke ${_telepon.text}.'
                : 'Masukkan nomor WhatsApp. Kami kirim kode 6 angka. Nomor baru otomatis didaftarkan.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s24),
          if (!_kodeTerkirim) ...[
            AppTextField(
              key: K.loginPhone,
              label: 'Nomor WhatsApp',
              hint: '0812 3456 7890',
              controller: _telepon,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              errorText: galatKolom?['telepon']?.first,
              onSubmitted: (_) => _kirimKode(),
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              key: K.loginSubmit,
              label: 'Kirim kode',
              loading: _proses,
              expand: true,
              onPressed: _proses ? null : _kirimKode,
            ),
          ] else ...[
            OtpInput(
              key: K.otpInput,
              enabled: !_proses,
              autofocus: true,
              errorText: galatKolom?['kode']?.first,
              onCompleted: _verifikasi,
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Ganti nomor',
              variant: AppButtonVariant.text,
              onPressed: _proses
                  ? null
                  : () => setState(() => _kodeTerkirim = false),
            ),
          ],
          if (galatUmum != null) ...[
            const SizedBox(height: AppSpace.s12),
            FieldErrorText(galatUmum),
          ],
        ],
      ),
    );
  }
}
