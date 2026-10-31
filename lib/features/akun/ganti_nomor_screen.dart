import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Satu bukti nomor yang sudah diterima: id dan token tantangan, serta nomor tersamar untuk ditampilkan.
typedef BuktiWa = ({String id, String token, String tersamar});

/// Ganti nomor HP (PRD §7.1, K-112): dua bukti lewat WhatsApp balik, dari nomor sekarang lalu dari nomor baru, lalu konfirmasi.
/// Perangkat lain keluar dari akun setelah nomor diganti; perangkat ini tetap masuk.
class GantiNomorScreen extends ConsumerStatefulWidget {
  const GantiNomorScreen({
    super.key,
    this.intervalPeriksa = const Duration(seconds: 3),
  });

  final Duration intervalPeriksa;

  @override
  ConsumerState<GantiNomorScreen> createState() => _GantiNomorScreenState();
}

class _GantiNomorScreenState extends ConsumerState<GantiNomorScreen> {
  BuktiWa? _lama;
  BuktiWa? _baru;
  bool _proses = false;
  bool _selesai = false;
  String? _galat;

  Future<void> _ganti() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final akun =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/me/telepon/wa',
                    data: {
                      'id_lama': _lama!.id,
                      'token_lama': _lama!.token,
                      'id_baru': _baru!.id,
                      'token_baru': _baru!.token,
                    },
                  )
              as Json;
      ref.read(sessionProvider.notifier).ganti(Akun.fromJson(akun));
      if (mounted) setState(() => _selesai = true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _galat = e.fields['telepon_baru']?.first ?? pesanGalat(e),
        );
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ganti nomor HP',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _selesai ? _hasil(context) : _langkah(context),
      ),
    );
  }

  List<Widget> _hasil(BuildContext context) => [
    Text('Nomor HP berhasil diganti.', style: context.text.h1),
    const SizedBox(height: AppSpace.s8),
    Text(
      'Perangkat lain sudah keluar dari akunmu. Masuk berikutnya memakai nomor yang baru.',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s24),
    AppButton(label: 'Kembali', expand: true, onPressed: () => context.pop()),
  ];

  List<Widget> _langkah(BuildContext context) => [
    Text(
      'Untuk keamanan akunmu, kami butuh bukti dari nomor yang sekarang dan dari nomor yang baru. Keduanya lewat pesan WhatsApp ke Pramu, gratis.',
      style: context.text.body,
    ),
    const SizedBox(height: AppSpace.s16),
    _Langkah(
      judul: 'Langkah 1: dari nomor yang sekarang',
      isi: 'Kirim kode dari nomor WhatsApp yang sekarang kamu pakai di Pramu.',
      arah: 'LAMA',
      bukti: _lama,
      interval: widget.intervalPeriksa,
      onDiterima: (b) => setState(() => _lama = b),
    ),
    if (_lama != null) ...[
      const SizedBox(height: AppSpace.s12),
      _Langkah(
        judul: 'Langkah 2: dari nomor yang baru',
        isi: 'Kirim kode dari nomor WhatsApp baru yang belum dipakai akun Pramu lain.',
        arah: 'BARU',
        bukti: _baru,
        interval: widget.intervalPeriksa,
        onDiterima: (b) => setState(() => _baru = b),
      ),
    ],
    if (_lama != null && _baru != null) ...[
      const SizedBox(height: AppSpace.s16),
      Text(
        'Ganti nomor dari ${_lama!.tersamar} ke ${_baru!.tersamar}? Perangkat lain akan keluar dari akunmu.',
        style: context.text.body,
      ),
      if (_galat != null) ...[
        const SizedBox(height: AppSpace.s8),
        FieldErrorText(_galat!),
      ],
      const SizedBox(height: AppSpace.s12),
      AppButton(
        label: 'Ya, ganti nomor',
        loading: _proses,
        expand: true,
        onPressed: _proses ? null : _ganti,
      ),
    ],
  ];
}

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.judul,
    required this.isi,
    required this.arah,
    required this.bukti,
    required this.interval,
    required this.onDiterima,
  });

  final String judul;
  final String isi;
  final String arah;
  final BuktiWa? bukti;
  final Duration interval;
  final void Function(BuktiWa) onDiterima;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(judul, style: context.text.h3),
        Text(isi, style: context.text.bodySm),
        const SizedBox(height: AppSpace.s8),
        if (bukti != null)
          Text('Nomor ${bukti!.tersamar} terbaca.', style: context.text.body)
        else
          _BuktiPanel(arah: arah, interval: interval, onDiterima: onDiterima),
      ],
    ),
  );
}

/// Membuat tantangan terikat ke pengguna yang masuk, menampilkan kode, dan memeriksa status berkala sampai diterima.
class _BuktiPanel extends ConsumerStatefulWidget {
  const _BuktiPanel({
    required this.arah,
    required this.interval,
    required this.onDiterima,
  });

  final String arah;
  final Duration interval;
  final void Function(BuktiWa) onDiterima;

  @override
  ConsumerState<_BuktiPanel> createState() => _BuktiPanelState();
}

class _BuktiPanelState extends ConsumerState<_BuktiPanel> {
  Json? _tantangan;
  String _status = 'MULAI';
  bool _proses = false;
  String? _galat;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _mulai() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final t =
          await ref
                  .read(apiClientProvider)
                  .post('/me/telepon/wa/tantangan', data: {'arah': widget.arah})
              as Json;
      _timer?.cancel();
      _timer = Timer.periodic(widget.interval, (_) => _periksa());
      if (mounted) {
        setState(() {
          _tantangan = t;
          _status = 'MENUNGGU';
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

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
      final status = s['status'] as String;
      if (status != 'MENUNGGU') _timer?.cancel();
      setState(() => _status = status);
      if (status == 'DITERIMA') {
        widget.onDiterima((
          id: _tantangan!['id'] as String,
          token: _tantangan!['token'] as String,
          tersamar: s['telepon_tersamar'] as String? ?? '',
        ));
      }
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

  @override
  Widget build(BuildContext context) {
    final mulaiLagi = _tantangan == null || _status == 'KEDALUWARSA';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status == 'KEDALUWARSA')
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: Text(
              'Kode sudah kedaluwarsa. Buat kode baru untuk mencoba lagi.',
              style: context.text.body,
            ),
          ),
        if (mulaiLagi)
          AppButton(
            label: _status == 'KEDALUWARSA'
                ? 'Buat kode baru'
                : (widget.arah == 'LAMA'
                      ? 'Mulai dari nomor sekarang'
                      : 'Mulai dari nomor baru'),
            loading: _proses,
            expand: true,
            onPressed: _proses ? null : _mulai,
          )
        else ...[
          Text(
            'Buka WhatsApp dan kirim pesan berisi kode ini ke Pramu. Jangan ubah isinya.',
            style: context.text.bodySm,
          ),
          const SizedBox(height: AppSpace.s8),
          Center(
            child: Text(
              _tantangan!['kode'] as String,
              style: context.text.h1,
              semanticsLabel: 'Kode ${_tantangan!['kode']}',
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            label: 'Buka WhatsApp',
            expand: true,
            onPressed: _bukaWhatsApp,
          ),
          Text('Menunggu pesanmu masuk…', style: context.text.caption),
        ],
        if (_galat != null) ...[
          const SizedBox(height: AppSpace.s8),
          FieldErrorText(_galat!),
        ],
      ],
    );
  }
}
