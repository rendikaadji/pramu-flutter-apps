import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Kategori laporan (PRD §21.2) dengan label bahasa pengguna.
const kategoriLaporan = {
  'PERILAKU_TIDAK_PANTAS': 'Perilaku tidak pantas',
  'IDENTITAS_PALSU': 'Identitas palsu',
  'PEMBAYARAN': 'Masalah pembayaran',
  'KEKERASAN_PENCURIAN_PELECEHAN': 'Kekerasan, pencurian, atau pelecehan',
  'LAINNYA': 'Lainnya',
};

/// Form ulasan setelah pekerjaan selesai (PRD §21.1). Ulasan tampil bersamaan, jadi tidak ada balasan atau pembalasan.
/// Mengembalikan true bila tersimpan; penolakan server (belum selesai, sudah diulas, lewat 7 hari) ditampilkan apa adanya.
Future<bool> tulisUlasan(BuildContext context, String penugasanId) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormUlasan(penugasanId: penugasanId),
    ) ??
    false;

/// Form laporan terhadap pihak yang pernah punya ajuan denganmu (PRD §21.2). Laporan dipastikan admin dulu sebelum
/// tampil sebagai badge; pelapor tidak pernah diberi tahu hasil ke pihak lain.
Future<bool> laporkan(BuildContext context, String terlaporProfilId) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormLaporan(terlaporProfilId: terlaporProfilId),
    ) ??
    false;

class _FormUlasan extends ConsumerStatefulWidget {
  const _FormUlasan({required this.penugasanId});

  final String penugasanId;

  @override
  ConsumerState<_FormUlasan> createState() => _FormUlasanState();
}

class _FormUlasanState extends ConsumerState<_FormUlasan> {
  final _catatan = TextEditingController();
  final _kunci = newIdempotencyKey();
  int _bintang = 0;
  bool _proses = false;
  String? _galat;

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/penugasan/${widget.penugasanId}/ulasan',
            data: {
              'bintang': _bintang,
              if (_catatan.text.trim().isNotEmpty)
                'catatan': _catatan.text.trim(),
            },
            options: ApiClient.idempotent(_kunci),
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Lembar(
    judul: 'Beri ulasan',
    anak: [
      Text(
        'Ulasanmu tampil bersamaan dengan ulasan pihak lain, jadi jujur saja.',
        style: context.text.bodySm,
      ),
      const SizedBox(height: AppSpace.s12),
      Center(
        child: RatingStars(
          value: _bintang.toDouble(),
          onChanged: (v) => setState(() => _bintang = v),
        ),
      ),
      const SizedBox(height: AppSpace.s12),
      AppTextField(
        label: 'Catatan (boleh dikosongkan)',
        controller: _catatan,
        maxLength: 500,
        maxLines: 3,
      ),
      if (_galat != null) FieldErrorText(_galat!),
      const SizedBox(height: AppSpace.s12),
      AppButton(
        label: 'Kirim ulasan',
        loading: _proses,
        expand: true,
        onPressed: _bintang == 0 || _proses ? null : _kirim,
      ),
    ],
  );
}

class _FormLaporan extends ConsumerStatefulWidget {
  const _FormLaporan({required this.terlaporProfilId});

  final String terlaporProfilId;

  @override
  ConsumerState<_FormLaporan> createState() => _FormLaporanState();
}

class _FormLaporanState extends ConsumerState<_FormLaporan> {
  final _catatan = TextEditingController();
  final _kunci = newIdempotencyKey();
  String? _kategori;
  bool _proses = false;
  String? _galat;

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/laporan',
            data: {
              'terlapor_profil_id': widget.terlaporProfilId,
              'kategori': _kategori,
              if (_catatan.text.trim().isNotEmpty)
                'catatan': _catatan.text.trim(),
            },
            options: ApiClient.idempotent(_kunci),
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Lembar(
    judul: 'Laporkan',
    anak: [
      Text(
        'Admin Pramu memeriksa setiap laporan. Pihak yang dilaporkan tidak diberi tahu siapa pelapornya.',
        style: context.text.bodySm,
      ),
      const SizedBox(height: AppSpace.s8),
      RadioGroup<String>(
        groupValue: _kategori,
        onChanged: (v) => setState(() => _kategori = v),
        child: Column(
          children: [
            for (final e in kategoriLaporan.entries)
              RadioListTile<String>(title: Text(e.value), value: e.key),
          ],
        ),
      ),
      AppTextField(
        label: 'Ceritakan singkat (boleh dikosongkan)',
        controller: _catatan,
        maxLength: 500,
        maxLines: 3,
      ),
      if (_galat != null) FieldErrorText(_galat!),
      const SizedBox(height: AppSpace.s12),
      AppButton(
        label: 'Kirim laporan',
        loading: _proses,
        expand: true,
        onPressed: _kategori == null || _proses ? null : _kirim,
      ),
    ],
  );
}

class _Lembar extends StatelessWidget {
  const _Lembar({required this.judul, required this.anak});

  final String judul;
  final List<Widget> anak;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s16,
        AppSpace.s16,
        AppSpace.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(judul, style: context.text.h2),
          const SizedBox(height: AppSpace.s8),
          ...anak,
        ],
      ),
    ),
  );
}
