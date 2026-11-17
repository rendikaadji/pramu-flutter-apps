import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/akun/unggah.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

final _verifikasiProvider = FutureProvider.autoDispose<Json>(
  (ref) async => await ref.watch(apiClientProvider).get('/verifikasi') as Json,
);

/// Langkah KTP (PRD §7.4): foto KTP dan swafoto memegang KTP, lalu diperiksa. Layar pemanggilnya dibungkus
/// [SecureScreenGuard] agar tidak bisa direkam atau tampil di daftar aplikasi terbuka (MOB-SEC-09).
class LangkahKtp extends ConsumerStatefulWidget {
  const LangkahKtp({super.key});

  @override
  ConsumerState<LangkahKtp> createState() => _LangkahKtpState();
}

class _LangkahKtpState extends ConsumerState<LangkahKtp> {
  Uint8List? _ktp;
  Uint8List? _swafoto;
  String _kunci = newIdempotencyKey();
  bool _proses = false;
  String? _galat;

  Future<void> _kirim() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final storage = ref.read(unggahDioProvider);
      final ktp = await unggahFoto(api, storage, 'FOTO_KTP', _ktp!);
      final swafoto = await unggahFoto(api, storage, 'SWAFOTO_KTP', _swafoto!);
      await api.post(
        '/verifikasi',
        data: {'foto_ktp_id': ktp, 'swafoto_ktp_id': swafoto},
        options: ApiClient.idempotent(_kunci),
      );
      _kunci = newIdempotencyKey();
      await ref.read(sessionProvider.notifier).muatUlang();
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(_verifikasiProvider).value;
    final alasan = status?['status'] == 'GAGAL'
        ? status!['alasan'] as String?
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Verifikasi KTP', style: context.text.h1),
        const SizedBox(height: AppSpace.s8),
        Text(
          'KTP hanya dipakai untuk memastikan kamu orang sungguhan dan berusia 18 tahun ke atas. Foto KTP tidak pernah ditampilkan ke pengguna lain.',
          style: context.text.body,
        ),
        if (alasan != null) ...[
          const SizedBox(height: AppSpace.s12),
          FieldErrorText('Pemeriksaan sebelumnya gagal: $alasan'),
        ],
        const SizedBox(height: AppSpace.s16),
        SlotFoto(
          judul: '1. Foto KTP',
          petunjuk: 'Letakkan KTP di meja, seluruh kartu terlihat, tulisan terbaca, tanpa pantulan cahaya.',
          isi: _ktp,
          onAmbil: (b) => setState(() => _ktp = b),
        ),
        const SizedBox(height: AppSpace.s12),
        SlotFoto(
          judul: '2. Foto diri memegang KTP',
          petunjuk: 'Pegang KTP di samping wajah. Wajah dan KTP sama-sama terlihat jelas.',
          isi: _swafoto,
          onAmbil: (b) => setState(() => _swafoto = b),
        ),
        if (_galat != null) ...[
          const SizedBox(height: AppSpace.s8),
          FieldErrorText(_galat!),
        ],
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Kirim untuk diperiksa',
          loading: _proses,
          expand: true,
          onPressed: _ktp == null || _swafoto == null || _proses
              ? null
              : _kirim,
        ),
      ],
    );
  }
}

/// Langkah profil semua akun (PRD §7.3): foto diri, foto rumah, titik rumah, dan alamat, disimpan sekaligus.
class LangkahProfil extends ConsumerStatefulWidget {
  const LangkahProfil({super.key});

  @override
  ConsumerState<LangkahProfil> createState() => _LangkahProfilState();
}

class _LangkahProfilState extends ConsumerState<LangkahProfil> {
  final _alamat = TextEditingController();
  Uint8List? _diri;
  Uint8List? _rumah;
  ({double lintang, double bujur})? _lokasi;
  bool _cariLokasi = false;
  String? _galatLokasi;
  bool _proses = false;
  ApiException? _galat;

  @override
  void dispose() {
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _ambilLokasi() async {
    setState(() {
      _cariLokasi = true;
      _galatLokasi = null;
    });
    try {
      final l = await ref.read(ambilLokasiProvider)();
      if (mounted) setState(() => _lokasi = l);
    } on LokasiGagal catch (e) {
      if (mounted) setState(() => _galatLokasi = e.pesan);
    } finally {
      if (mounted) setState(() => _cariLokasi = false);
    }
  }

  Future<void> _simpan() async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final storage = ref.read(unggahDioProvider);
      final diri = await unggahFoto(api, storage, 'FOTO_DIRI', _diri!);
      final rumah = await unggahFoto(api, storage, 'FOTO_RUMAH', _rumah!);
      final akun = await api.put(
        '/me/profil',
        data: {
          'foto_diri_id': diri,
          'foto_rumah_id': rumah,
          'lokasi': {'lintang': _lokasi!.lintang, 'bujur': _lokasi!.bujur},
          'alamat': _alamat.text.trim(),
        },
      ) as Json;
      ref.read(sessionProvider.notifier).ganti(Akun.fromJson(akun));
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = e);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  bool get _lengkap =>
      _diri != null &&
      _rumah != null &&
      _lokasi != null &&
      _alamat.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Foto dan alamat rumah', style: context.text.h1),
      const SizedBox(height: AppSpace.s8),
      Text(
        'Foto diri baru terlihat oleh pihak lain setelah kalian sepakat. Alamat lengkap dan titik rumah tidak pernah ditampilkan; yang terlihat hanya kecamatan dan perkiraan jarak.',
        style: context.text.body,
      ),
      const SizedBox(height: AppSpace.s16),
      SlotFoto(
        judul: '1. Foto diri',
        petunjuk: 'Wajah terlihat jelas, tanpa kacamata hitam atau masker.',
        isi: _diri,
        onAmbil: (b) => setState(() => _diri = b),
      ),
      const SizedBox(height: AppSpace.s12),
      SlotFoto(
        judul: '2. Foto rumah',
        petunjuk: 'Bagian depan rumah dari jalan.',
        isi: _rumah,
        bolehGaleri: true,
        onAmbil: (b) => setState(() => _rumah = b),
      ),
      const SizedBox(height: AppSpace.s12),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('3. Titik rumah', style: context.text.h3),
            const SizedBox(height: AppSpace.s4),
            Text(
              _lokasi == null
                  ? 'Ambil saat kamu sedang berada di rumah.'
                  : 'Titik rumah sudah diambil.',
              style: context.text.bodySm,
            ),
            if (_galatLokasi != null) FieldErrorText(_galatLokasi!),
            const SizedBox(height: AppSpace.s8),
            AppButton(
              label: _lokasi == null
                  ? 'Pakai lokasi saya sekarang'
                  : 'Ambil ulang lokasi',
              variant: _lokasi == null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              loading: _cariLokasi,
              onPressed: _cariLokasi ? null : _ambilLokasi,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s12),
      AppTextField(
        label: '4. Alamat lengkap',
        hint: 'Nama jalan, nomor rumah, RT/RW, patokan',
        controller: _alamat,
        maxLength: 300,
        maxLines: 3,
        errorText: _galat?.fields['alamat']?.first,
        onChanged: (_) => setState(() {}),
      ),
      if (_galat != null && _galat!.fields['alamat'] == null) ...[
        const SizedBox(height: AppSpace.s8),
        FieldErrorText(
          _galat!.fields['lokasi.lintang']?.first ??
              _galat!.fields['lokasi.bujur']?.first ??
              pesanGalat(_galat!),
        ),
      ],
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Simpan',
        loading: _proses,
        expand: true,
        onPressed: _lengkap && !_proses ? _simpan : null,
      ),
    ],
  );
}

/// Satu kotak foto: judul, petunjuk, pratinjau, dan tombol ambil.
class SlotFoto extends ConsumerWidget {
  const SlotFoto({
    super.key,
    required this.judul,
    required this.petunjuk,
    required this.isi,
    required this.onAmbil,
    this.bolehGaleri = false,
  });

  final String judul;
  final String petunjuk;
  final Uint8List? isi;
  final ValueChanged<Uint8List> onAmbil;
  final bool bolehGaleri;

  /// Kamera atau galeri yang gagal dibuka tidak boleh diam saja: pengguna diberi tahu dan boleh mencoba lagi.
  Future<void> _ambil(
    BuildContext context,
    WidgetRef ref, {
    bool galeri = false,
  }) async {
    try {
      final b = await ref.read(ambilFotoProvider)(galeri: galeri);
      if (b != null) onAmbil(b);
    } catch (e) {
      debugPrint('ambil foto gagal: $e');
      if (context.mounted) {
        AppSnack.show(
          context,
          galeri ? 'Galeri tidak bisa dibuka. Coba lagi.' : 'Kamera tidak bisa dibuka atau fotonya gagal dibaca. Coba lagi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(judul, style: context.text.h3),
        const SizedBox(height: AppSpace.s4),
        Text(petunjuk, style: context.text.bodySm),
        if (isi != null) ...[
          const SizedBox(height: AppSpace.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.memory(
              isi!,
              height: 160,
              fit: BoxFit.cover,
              semanticLabel: '$judul sudah diambil',
            ),
          ),
        ],
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: isi == null ? 'Ambil foto' : 'Ambil ulang',
          variant: isi == null
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: () => _ambil(context, ref),
        ),
        if (bolehGaleri)
          AppButton(
            label: 'Pilih dari galeri',
            variant: AppButtonVariant.text,
            onPressed: () => _ambil(context, ref, galeri: true),
          ),
      ],
    ),
  );
}
