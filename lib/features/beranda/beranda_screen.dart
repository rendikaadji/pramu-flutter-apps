import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/batas_chip.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

final berandaProvider = FutureProvider.autoDispose<Json>((ref) async {
  final peran = ref.watch(peranAktifProvider);
  return await ref
          .watch(apiClientProvider)
          .get('/beranda', query: {'peran': peran})
      as Json;
});

/// Status masa perkenalan (PRD §6.1). Teks dari server, tanpa angka kuota; gagal memuat = banner tidak tampil.
final perkenalanProvider = FutureProvider.autoDispose<Json>(
  (ref) async => await ref.watch(apiClientProvider).get('/perkenalan') as Json,
);

class _BannerPerkenalan extends ConsumerWidget {
  const _BannerPerkenalan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(perkenalanProvider).value;
    if (p == null || p['aktif'] != true) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: AppCard(
        child: Text(p['pesan'] as String, style: context.text.bodySm),
      ),
    );
  }
}

/// S-05 Beranda: semua permintaan berbatas waktu tampil di atas sebagai kartu tindakan (brief v2 §8.1).
class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peran = ref.watch(peranAktifProvider);
    final beranda = ref.watch(berandaProvider);
    final nama = ref.watch(sessionProvider).value?.namaDepan;
    return AppScaffold(
      title: nama == null ? 'Beranda' : 'Halo, $nama',
      actions: [
        AppIconButton(
          icon: LucideIcons.messageCircle,
          label: 'Pesan',
          onPressed: () => context.push('/percakapan'),
        ),
        AppIconButton(
          icon: LucideIcons.bell,
          label: 'Notifikasi',
          onPressed: () => context.push('/notifikasi'),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(berandaProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            const _BannerPerkenalan(),
            Muat(
              nilai: beranda,
              onUlangi: () => ref.invalidate(berandaProvider),
              isi: (data) => _Isi(data: data, majikan: peran == Peran.majikan),
            ),
          ],
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data, required this.majikan});

  final Json data;
  final bool majikan;

  @override
  Widget build(BuildContext context) {
    final kartu = (data['kartu_tindakan'] as List? ?? const []).cast<Json>();
    final berjalan = (data['penugasan_berjalan'] as List? ?? const [])
        .cast<Json>();
    final jobSaya = (data['job_saya'] as List? ?? const []).cast<Json>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Perlu dijawab', style: context.text.h2),
        const SizedBox(height: AppSpace.s8),
        if (kartu.isEmpty)
          Text(
            'Tidak ada yang perlu dijawab sekarang.',
            style: context.text.bodySm,
          ),
        for (final k in kartu) ...[
          _KartuTindakan(k),
          const SizedBox(height: AppSpace.s12),
        ],
        const SizedBox(height: AppSpace.s16),
        Text('Pekerjaan berjalan', style: context.text.h2),
        const SizedBox(height: AppSpace.s8),
        if (berjalan.isEmpty)
          Text('Belum ada pekerjaan berjalan.', style: context.text.bodySm),
        for (final p in berjalan) ...[
          AppCard(
            onTap: () => context.push('/penugasan/${p['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p['judul']} · ${p['label_status']}',
                  style: context.text.h3,
                ),
                const SizedBox(height: AppSpace.s8),
                ProfilBaris(
                  profil: RingkasanProfil.fromJson(p['pihak_lain'] as Json),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        if (majikan) ...[
          const SizedBox(height: AppSpace.s16),
          Row(
            children: [
              Expanded(child: Text('Job saya', style: context.text.h2)),
              AppButton(
                label: 'Buat job',
                icon: LucideIcons.plus,
                expand: false,
                onPressed: () => context.push('/job/buat'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          if (jobSaya.isEmpty)
            Text(
              'Belum ada job. Buat job pertama, lalu kami tunjukkan pekerja yang cocok.',
              style: context.text.bodySm,
            ),
          for (final j in jobSaya) ...[
            AppCard(
              onTap: () => context.push('/job/${j['id']}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${j['judul']} · ${j['label_status']}',
                    style: context.text.h3,
                  ),
                  if (j['status'] == 'TERBUKA')
                    Text(
                      '${j['jumlah_kandidat_cocok']} pekerja cocok',
                      style: context.text.bodySm,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s12),
          ],
        ],
      ],
    );
  }
}

class _KartuTindakan extends StatelessWidget {
  const _KartuTindakan(this.k);

  final Json k;

  @override
  Widget build(BuildContext context) {
    final batas = BatasWaktu.fromJson(k['batas']);
    final tombol = (k['tombol'] as List? ?? const []).cast<Json>();
    return AppCard(
      color: context.tokens.warningContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (batas != null) ...[
            BatasChip(batas),
            const SizedBox(height: AppSpace.s8),
          ],
          Text(k['judul'] as String, style: context.text.h3),
          if (k['akibat_jika_diam'] != null)
            Text(k['akibat_jika_diam'] as String, style: context.text.bodySm),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final b in tombol)
                AppButton(
                  label: b['label'] as String,
                  expand: false,
                  onPressed: () => context.push(b['tujuan'] as String),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
