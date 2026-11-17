import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/penugasan/penugasan.dart';
import 'package:pramu_apps/features/penugasan/ulasan_laporan.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:pramu_apps/shared/baris_info.dart';
import 'package:pramu_apps/shared/batas_chip.dart';
import 'package:pramu_apps/shared/berhalaman.dart';
import 'package:pramu_apps/shared/daftar_aksi.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

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
              isi: (h) => Berhalaman(
                awal: h,
                isi: (baris, muatLagi) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    baris.isEmpty
                        ? const EmptyState(
                            title: 'Belum ada pekerjaan',
                            message: 'Pekerjaan yang sudah disepakati tampil di sini.',
                          )
                        : Column(
                            children: [
                              for (final p in baris) ...[
                                AppCard(
                                  onTap: () =>
                                      context.push('/penugasan/${p.id}'),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    ?muatLagi,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _kunciAksi = <String, String>{};

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
    // Kunci tetap sampai aksi berhasil, agar coba ulang setelah timeout tidak menjalankan aksi dua kali.
    final kunci = _kunciAksi.putIfAbsent('$id/$kode', newIdempotencyKey);
    await ref
        .read(apiClientProvider)
        .post(
          '/penugasan/$id/$kode',
          data: badan,
          options: ApiClient.idempotent(kunci),
        );
    _kunciAksi.remove('$id/$kode');
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
                if (p.batasKonfirmasi != null) ...[
                  const SizedBox(height: AppSpace.s4),
                  BatasChip(p.batasKonfirmasi!, label: 'Batas konfirmasi'),
                ],
                if (p.petaUrl != null)
                  AppButton(
                    label: 'Buka peta',
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        openMapUrl(ref.read(urlLauncherProvider), p.petaUrl),
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
                AppButton(
                  label: 'Beri ulasan',
                  variant: AppButtonVariant.text,
                  onPressed: () async {
                    if (await tulisUlasan(context, p.id) && context.mounted) {
                      AppSnack.show(context, 'Ulasan tersimpan. Terima kasih.');
                    }
                  },
                ),
                AppButton(
                  label: 'Laporkan',
                  variant: AppButtonVariant.text,
                  onPressed: () async {
                    if (await laporkan(context, p.pihakLain.id) &&
                        context.mounted) {
                      AppSnack.show(
                        context,
                        'Laporan diterima. Admin akan memeriksanya.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
