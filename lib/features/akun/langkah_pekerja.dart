import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/akun/unggah.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

const _hari = {
  'SEN': 'Senin',
  'SEL': 'Selasa',
  'RAB': 'Rabu',
  'KAM': 'Kamis',
  'JUM': 'Jumat',
  'SAB': 'Sabtu',
  'MIN': 'Minggu',
};

/// Langkah data pekerja (PRD §7.3, §10.3): jenis pekerjaan dengan upah terendah, dan hari tersedia.
/// Upah terendah menentukan kisaran yang terlihat oleh majikan; ujung atasnya ditetapkan sistem per jenis pekerjaan.
class LangkahDataPekerja extends ConsumerStatefulWidget {
  const LangkahDataPekerja({super.key});

  @override
  ConsumerState<LangkahDataPekerja> createState() => _LangkahDataPekerjaState();
}

class _LangkahDataPekerjaState extends ConsumerState<LangkahDataPekerja> {
  final _upah = <String, TextEditingController>{};
  final _keahlian = <String, TextEditingController>{};
  final _hariDipilih = <String>{};
  bool _proses = false;
  bool _cobaSimpan = false;
  String? _galat;

  @override
  void dispose() {
    for (final c in [..._upah.values, ..._keahlian.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pilih(Kategori k, bool aktif) => setState(() {
    if (aktif) {
      _upah.putIfAbsent(k.id, TextEditingController.new);
      if (k.namaBebas) _keahlian.putIfAbsent(k.id, TextEditingController.new);
    } else {
      _upah.remove(k.id)?.dispose();
      _keahlian.remove(k.id)?.dispose();
    }
  });

  /// Pesan galat untuk satu jenis pekerjaan yang dipilih, atau null bila isiannya sah.
  String? _periksa(Kategori k) {
    final v = parseRupiah(_upah[k.id]?.text ?? '');
    if (v == null || v <= 0) return 'Isi upah terendah dalam rupiah.';
    if (v % k.kelipatanTitik != 0) {
      return 'Upah harus kelipatan ${formatRupiah(k.kelipatanTitik)}.';
    }
    return null;
  }

  Future<void> _simpan(List<Kategori> semua) async {
    setState(() {
      _cobaSimpan = true;
      _galat = null;
    });
    final dipilih = [
      for (final k in semua)
        if (_upah.containsKey(k.id)) k,
    ];
    if (dipilih.isEmpty) {
      setState(() => _galat = 'Pilih minimal satu jenis pekerjaan.');
      return;
    }
    if (_hariDipilih.isEmpty) {
      setState(() => _galat = 'Pilih minimal satu hari kamu bisa bekerja.');
      return;
    }
    if (dipilih.any((k) => _periksa(k) != null) ||
        dipilih.any(
          (k) => k.namaBebas && (_keahlian[k.id]?.text.trim().isEmpty ?? true),
        )) {
      setState(() => _galat = 'Lengkapi isian yang ditandai merah.');
      return;
    }
    setState(() => _proses = true);
    try {
      await ref
          .read(apiClientProvider)
          .put(
            '/me/pekerja',
            data: {
              'hari_tersedia': [
                for (final h in _hari.keys)
                  if (_hariDipilih.contains(h)) h,
              ],
              'kategori': [
                for (final k in dipilih)
                  {
                    'kategori_id': k.id,
                    'titik_awal': parseRupiah(_upah[k.id]!.text),
                    if (k.namaBebas) 'keahlian': _keahlian[k.id]!.text.trim(),
                  },
              ],
            },
          );
      await ref.read(sessionProvider.notifier).muatUlang();
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _galat =
              e.fields['kategori']?.first ??
              e.fields['hari_tersedia']?.first ??
              pesanGalat(e),
        );
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategori = ref.watch(kategoriProvider);
    return Muat(
      nilai: kategori,
      onUlangi: () => ref.invalidate(kategoriProvider),
      isi: (semua) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pekerjaan yang kamu terima', style: context.text.h1),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Pilih jenis pekerjaan yang bisa kamu kerjakan, lalu isi upah terendah yang kamu mau. Majikan hanya melihat kisaran, bukan angka pastinya.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s16),
          for (final k in semua) ...[
            _KartuKategori(
              kategori: k,
              dipilih: _upah.containsKey(k.id),
              upah: _upah[k.id],
              keahlian: _keahlian[k.id],
              galat: _cobaSimpan && _upah.containsKey(k.id)
                  ? _periksa(k)
                  : null,
              galatKeahlian:
                  _cobaSimpan &&
                      k.namaBebas &&
                      _upah.containsKey(k.id) &&
                      (_keahlian[k.id]?.text.trim().isEmpty ?? true)
                  ? 'Tulis pekerjaan yang kamu bisa.'
                  : null,
              onPilih: (a) => _pilih(k, a),
              onUbah: () => setState(() {}),
            ),
            const SizedBox(height: AppSpace.s8),
          ],
          const SizedBox(height: AppSpace.s8),
          Text('Hari kamu bisa bekerja', style: context.text.h3),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final e in _hari.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: _hariDipilih.contains(e.key),
                  onSelected: (a) => setState(
                    () => a
                        ? _hariDipilih.add(e.key)
                        : _hariDipilih.remove(e.key),
                  ),
                ),
            ],
          ),
          if (_galat != null) ...[
            const SizedBox(height: AppSpace.s12),
            FieldErrorText(_galat!),
          ],
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Simpan',
            loading: _proses,
            expand: true,
            onPressed: _proses ? null : () => _simpan(semua),
          ),
        ],
      ),
    );
  }
}

class _KartuKategori extends StatelessWidget {
  const _KartuKategori({
    required this.kategori,
    required this.dipilih,
    required this.upah,
    required this.keahlian,
    required this.galat,
    required this.galatKeahlian,
    required this.onPilih,
    required this.onUbah,
  });

  final Kategori kategori;
  final bool dipilih;
  final TextEditingController? upah;
  final TextEditingController? keahlian;
  final String? galat;
  final String? galatKeahlian;
  final ValueChanged<bool> onPilih;
  final VoidCallback onUbah;

  @override
  Widget build(BuildContext context) {
    final v = parseRupiah(upah?.text ?? '');
    final sah =
        v != null &&
        v > 0 &&
        kategori.kelipatanTitik > 0 &&
        v % kategori.kelipatanTitik == 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.trailing,
              value: dipilih,
              onChanged: (a) => onPilih(a ?? false),
              title: Text(kategori.nama, style: context.text.h3),
              subtitle: Text(
                kategori.periodik
                    ? 'Rutin, mingguan atau bulanan'
                    : 'Sekali datang',
                style: context.text.bodySm,
              ),
            ),
          ),
          if (dipilih) ...[
            AppTextField(
              label: 'Upah terendah (Rp)',
              controller: upah,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              helper: sah && kategori.lebarRentang > 0
                  ? 'Majikan melihat kisaran ${formatRupiah(v)} – ${formatRupiah(v + kategori.lebarRentang)}.'
                  : 'Kelipatan ${formatRupiah(kategori.kelipatanTitik)}.',
              errorText: galat,
              onChanged: (_) => onUbah(),
            ),
            if (kategori.namaBebas) ...[
              const SizedBox(height: AppSpace.s8),
              AppTextField(
                label: 'Pekerjaan apa yang kamu bisa?',
                controller: keahlian,
                maxLength: 200,
                errorText: galatKeahlian,
                onChanged: (_) => onUbah(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Langkah video perkenalan (PRD §7.3): rekam sampai 60 detik. Majikan baru melihatnya setelah kalian sepakat.
class LangkahVideo extends ConsumerStatefulWidget {
  const LangkahVideo({super.key});

  @override
  ConsumerState<LangkahVideo> createState() => _LangkahVideoState();
}

class _LangkahVideoState extends ConsumerState<LangkahVideo> {
  static const _detikMaks = 60;
  // Sama dengan batas server: kamera HP merekam sekitar 1 MB per detik, jadi 60 detik hampir 65 MB.
  static const _byteMaks = 100 * 1024 * 1024;

  bool _proses = false;
  String? _galat;

  Future<void> _rekam() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final isi = await ref.read(ambilVideoProvider)(_detikMaks);
      if (isi == null) return;
      if (isi.length > _byteMaks) {
        setState(
          () => _galat = 'Videonya terlalu besar (maksimal 100 MB). Rekam lebih singkat, lalu coba lagi.',
        );
        return;
      }
      await _kirim(isi);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _galat = e.fields['berkas']?.first ?? pesanGalat(e));
      }
    } catch (e) {
      debugPrint('rekam video gagal: $e');
      if (mounted) {
        setState(
          () => _galat =
              'Kamera tidak bisa dibuka atau videonya gagal dibaca. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _kirim(Uint8List isi) async {
    await unggahBerkas(
      ref.read(apiClientProvider),
      ref.read(unggahDioProvider),
      'VIDEO_PERKENALAN',
      isi,
      'video/mp4',
    );
    await ref.read(sessionProvider.notifier).muatUlang();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Video perkenalan', style: context.text.h1),
      const SizedBox(height: AppSpace.s8),
      Text(
        'Rekam video singkat, paling lama 1 menit: perkenalkan diri dan ceritakan pengalamanmu. Majikan baru bisa melihatnya setelah kalian sepakat.',
        style: context.text.body,
      ),
      const SizedBox(height: AppSpace.s12),
      Text(
        'Tips: rekam di tempat terang, bicara pelan dan jelas.',
        style: context.text.bodySm,
      ),
      if (_galat != null) ...[
        const SizedBox(height: AppSpace.s12),
        FieldErrorText(_galat!),
      ],
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Rekam video',
        loading: _proses,
        expand: true,
        onPressed: _proses ? null : _rekam,
      ),
    ],
  );
}

/// Langkah biaya registrasi (PRD §7.5): satu kali, lewat QRIS. Gratis selama masa perkenalan, jadi langkah ini
/// hanya muncul bila server meminta.
class LangkahRegistrasi extends ConsumerStatefulWidget {
  const LangkahRegistrasi({super.key});

  @override
  ConsumerState<LangkahRegistrasi> createState() => _LangkahRegistrasiState();
}

class _LangkahRegistrasiState extends ConsumerState<LangkahRegistrasi> {
  String _kunci = newIdempotencyKey();
  bool _proses = false;
  String? _galat;

  Future<void> _bayar() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final t =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/tagihan',
                    data: {'jenis': 'REGISTRASI'},
                    options: ApiClient.idempotent(_kunci),
                  )
              as Json;
      _kunci = newIdempotencyKey();
      if (!mounted) return;
      await context.push('/tagihan/${t['id']}');
      // Sesudah QR dibayar dan layar ditutup, server menentukan apakah langkah ini selesai.
      await ref.read(sessionProvider.notifier).muatUlang();
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Biaya registrasi', style: context.text.h1),
      const SizedBox(height: AppSpace.s8),
      Text(
        'Biaya pendaftaran dibayar satu kali, lalu kamu bisa mulai mengajukan pekerjaan. Bayar lewat QRIS dari aplikasi bank atau dompet digital.',
        style: context.text.body,
      ),
      if (_galat != null) ...[
        const SizedBox(height: AppSpace.s12),
        FieldErrorText(_galat!),
      ],
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Bayar sekarang',
        loading: _proses,
        expand: true,
        onPressed: _proses ? null : _bayar,
      ),
    ],
  );
}
