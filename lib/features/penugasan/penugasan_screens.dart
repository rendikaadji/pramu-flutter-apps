import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/penugasan/penugasan.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/baris_info.dart';
import 'package:pramu_apps/shared/daftar_aksi.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';
import 'package:url_launcher/url_launcher.dart';

/// Daftar pekerjaan (penugasan) untuk peran aktif.
class PenugasanDaftarScreen extends ConsumerWidget {
  const PenugasanDaftarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(penugasanDaftarProvider);
    return AppScaffold(
      title: 'Pekerjaan',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(penugasanDaftarProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: daftar,
              onUlangi: () => ref.invalidate(penugasanDaftarProvider),
              isi: (h) => h.items.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada pekerjaan',
                      message:
                          'Pekerjaan yang sudah disepakati tampil di sini.',
                    )
                  : Column(
                      children: [
                        for (final p in h.items) ...[
                          AppCard(
                            onTap: () => context.push('/penugasan/${p.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.judul} · ${p.labelStatus}',
                                  style: context.text.h3,
                                ),
                                const SizedBox(height: AppSpace.s8),
                                ProfilBaris(profil: p.pihakLain),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.s12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// S-12 Pekerjaan berjalan: semua aksi (PRD §14–16) dari `aksi_tersedia`; batalkan meminta alasan, usulan meminta tanggal.
class PenugasanDetailScreen extends ConsumerWidget {
  const PenugasanDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _jalankan(
    BuildContext context,
    WidgetRef ref,
    String kode,
  ) async {
    Map<String, dynamic>? badan;
    if (kode == 'batalkan') {
      final alasan = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Alasan membatalkan')),
              for (final e in alasanBatal.entries)
                ListTile(
                  title: Text(e.value),
                  onTap: () => Navigator.pop(ctx, e.key),
                ),
            ],
          ),
        ),
      );
      if (alasan == null) return;
      badan = {'alasan_kode': alasan};
    } else if (kode == 'usulan-efektif') {
      final hariIni = toWib(DateTime.now());
      final tgl = await showDatePicker(
        context: context,
        helpText: 'Hari terakhir',
        initialDate: hariIni,
        firstDate: DateTime(hariIni.year, hariIni.month, hariIni.day),
        lastDate: hariIni.add(const Duration(days: 365)),
      );
      if (tgl == null) return;
      badan = {
        'tanggal':
            '${tgl.year}-${tgl.month.toString().padLeft(2, '0')}-${tgl.day.toString().padLeft(2, '0')}',
      };
    }
    await ref
        .read(apiClientProvider)
        .post(
          '/penugasan/$id/$kode',
          data: badan,
          options: ApiClient.idempotent(newIdempotencyKey()),
        );
    ref.invalidate(penugasanProvider(id));
    ref.invalidate(penugasanDaftarProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final penugasan = ref.watch(penugasanProvider(id));
    return AppScaffold(
      title: penugasan.value?.judul ?? 'Pekerjaan',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: penugasan,
            onUlangi: () => ref.invalidate(penugasanProvider(id)),
            isi: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.hariKe == null
                      ? p.labelStatus
                      : '${p.labelStatus} · Hari ke-${p.hariKe}',
                  style: context.text.h3,
                ),
                const SizedBox(height: AppSpace.s12),
                AppCard(child: ProfilBaris(profil: p.pihakLain)),
                const SizedBox(height: AppSpace.s12),
                if (p.harga != null)
                  BarisInfo('Upah disepakati', p.harga!.teks),
                if (p.alamat != null) BarisInfo('Alamat', p.alamat!),
                if (p.tanggalBerakhir != null)
                  BarisInfo('Berakhir pada', p.tanggalBerakhir!),
                if (p.batasKonfirmasi != null)
                  BarisInfo(
                    'Batas konfirmasi',
                    '${formatDateTime(p.batasKonfirmasi!.sampai)} (${p.batasKonfirmasi!.teks})',
                  ),
                if (p.petaUrl != null)
                  AppButton(
                    label: 'Buka peta',
                    variant: AppButtonVariant.text,
                    onPressed: () => launchUrl(
                      Uri.parse(p.petaUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                const SizedBox(height: AppSpace.s16),
                DaftarAksi(
                  aksi: p.aksi,
                  jalankan: (kode) => _jalankan(context, ref, kode),
                ),
                if (p.percakapanId != null)
                  AppButton(
                    label: 'Buka chat',
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        context.push('/percakapan/${p.percakapanId}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
