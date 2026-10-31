import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:url_launcher/url_launcher.dart';

const _namaDokumen = {
  'KETENTUAN_LAYANAN': 'Ketentuan layanan',
  'KEBIJAKAN_PRIVASI': 'Kebijakan privasi',
  'DATA_REGISTRASI': 'Pemakaian data pendaftaran',
  'DATA_LOKASI': 'Pemakaian data lokasi',
};

final _dokumenTerbaruProvider = FutureProvider.autoDispose<List<Json>>((
  ref,
) async {
  final data =
      await ref.watch(apiClientProvider).get('/persetujuan/terbaru') as List;
  return data.cast<Json>();
});

/// S-02 Persetujuan versi terbaru (PRD §7.2). Wajib sebelum data pengguna dipakai.
class PersetujuanScreen extends ConsumerStatefulWidget {
  const PersetujuanScreen({super.key});

  @override
  ConsumerState<PersetujuanScreen> createState() => _PersetujuanScreenState();
}

class _PersetujuanScreenState extends ConsumerState<PersetujuanScreen> {
  final _centang = <String>{};
  final _kunci = newIdempotencyKey();
  bool _proses = false;
  String? _galat;

  Future<void> _setujui(List<Json> dokumen) async {
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/persetujuan',
            data: {
              'persetujuan': [
                for (final d in dokumen)
                  {'jenis': d['jenis'], 'versi': d['versi']},
              ],
            },
            options: ApiClient.idempotent(_kunci),
          );
      await ref.read(sessionProvider.notifier).muatUlang();
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dokumen = ref.watch(_dokumenTerbaruProvider);
    return AppScaffold(
      title: 'Persetujuan',
      scrollable: true,
      body: Muat(
        nilai: dokumen,
        onUlangi: () => ref.invalidate(_dokumenTerbaruProvider),
        isi: (daftar) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sebelum mulai', style: context.text.h1),
            const SizedBox(height: AppSpace.s8),
            Text(
              'Baca dan setujui dokumen berikut. Kamu bisa membukanya kapan saja dari menu Akun.',
              style: context.text.body,
            ),
            const SizedBox(height: AppSpace.s16),
            for (final d in daftar)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _centang.contains(d['jenis']),
                onChanged: (v) => setState(
                  () => v!
                      ? _centang.add(d['jenis'] as String)
                      : _centang.remove(d['jenis']),
                ),
                title: Text(_namaDokumen[d['jenis']] ?? d['jenis'] as String),
                subtitle: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse(d['url'] as String),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Baca (versi ${d['versi']})',
                    style: TextStyle(
                      color: context.tokens.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Setujui dan lanjutkan',
              expand: true,
              loading: _proses,
              onPressed: _centang.length == daftar.length && !_proses
                  ? () => _setujui(daftar)
                  : null,
            ),
            if (_galat != null) ...[
              const SizedBox(height: AppSpace.s12),
              FieldErrorText(_galat!),
            ],
          ],
        ),
      ),
    );
  }
}

/// S-03 bagian pertama: pilih peran (PRD §3.1). Peran kedua bisa ditambah nanti dari menu Akun.
class PeranScreen extends ConsumerStatefulWidget {
  const PeranScreen({super.key});

  @override
  ConsumerState<PeranScreen> createState() => _PeranScreenState();
}

class _PeranScreenState extends ConsumerState<PeranScreen> {
  String? _proses;
  String? _galat;

  Future<void> _pilih(String peran) async {
    setState(() {
      _proses = peran;
      _galat = null;
    });
    try {
      final akun =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/me/peran',
                    data: {'peran': peran},
                    options: ApiClient.idempotent(newIdempotencyKey()),
                  )
              as Json;
      ref.read(peranAktifProvider.notifier).pilih(peran);
      ref.read(sessionProvider.notifier).ganti(Akun.fromJson(akun));
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = null);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Pilih peran',
    scrollable: true,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kamu ingin…', style: context.text.h1),
        const SizedBox(height: AppSpace.s16),
        _Pilihan(
          judul: 'Mencari pekerja rumah',
          isi: 'Buat job, lihat pekerja yang cocok, dan sepakati upah.',
          proses: _proses == Peran.majikan,
          onTap: _proses == null ? () => _pilih(Peran.majikan) : null,
        ),
        const SizedBox(height: AppSpace.s12),
        _Pilihan(
          judul: 'Mencari pekerjaan',
          isi: 'Cari job di sekitarmu sesuai jenis pekerjaan dan kisaran upahmu.',
          proses: _proses == Peran.pekerja,
          onTap: _proses == null ? () => _pilih(Peran.pekerja) : null,
        ),
        if (_galat != null) ...[
          const SizedBox(height: AppSpace.s12),
          FieldErrorText(_galat!),
        ],
      ],
    ),
  );
}

class _Pilihan extends StatelessWidget {
  const _Pilihan({
    required this.judul,
    required this.isi,
    required this.proses,
    this.onTap,
  });

  final String judul;
  final String isi;
  final bool proses;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul, style: context.text.h3),
              const SizedBox(height: AppSpace.s4),
              Text(isi, style: context.text.bodySm),
            ],
          ),
        ),
        if (proses)
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    ),
  );
}

const _namaLangkah = {
  'KTP': 'Verifikasi KTP',
  'FOTO_DIRI': 'Foto diri',
  'FOTO_RUMAH': 'Foto rumah',
  'LOKASI': 'Lokasi dan alamat rumah',
  'DATA_PEKERJA': 'Jenis pekerjaan dan kisaran upah',
  'VIDEO': 'Video perkenalan',
  'BAYAR_REGISTRASI': 'Biaya registrasi',
};

/// Langkah onboarding yang layarnya belum dibangun di aplikasi ini.
/// shortcut: KTP, foto, lokasi, data pekerja, video, dan biaya registrasi belum punya layar; bangun bersama integrasi langkah 9 (OCR, peta, S3, pembayaran).
class LanjutkanScreen extends ConsumerWidget {
  const LanjutkanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final akun = ref.watch(sessionProvider).value;
    final aktif = ref.watch(peranAktifProvider);
    final langkah = akun?.langkahUntuk(aktif);
    // Peran lain yang sudah siap: pengguna bisa kembali memakainya tanpa menunggu langkah peran ini.
    final siap = akun?.peranSiap;
    const namaPeran = {Peran.majikan: 'majikan', Peran.pekerja: 'pekerja'};
    return AppScaffold(
      title: 'Lanjutkan pendaftaran',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyState(
            title: _namaLangkah[langkah] ?? 'Langkah berikutnya',
            message: 'Langkah ini sedang disiapkan di aplikasi. Kami beri tahu begitu bisa dilanjutkan.',
            actionLabel: 'Periksa lagi',
            onAction: () => ref.read(sessionProvider.notifier).muatUlang(),
          ),
          if (siap != null && siap != aktif)
            AppButton(
              label: 'Pakai sebagai ${namaPeran[siap] ?? siap}',
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  ref.read(peranAktifProvider.notifier).pilih(siap),
            ),
        ],
      ),
    );
  }
}
