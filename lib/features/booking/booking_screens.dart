import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/booking/booking.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/baris_info.dart';
import 'package:pramu_apps/shared/daftar_aksi.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

/// Daftar ajuan untuk peran aktif.
class BookingDaftarScreen extends ConsumerWidget {
  const BookingDaftarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(bookingDaftarProvider);
    return AppScaffold(
      title: 'Ajuan',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(bookingDaftarProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: daftar,
              onUlangi: () => ref.invalidate(bookingDaftarProvider),
              isi: (h) => h.items.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada ajuan',
                      message:
                          'Ajuan yang kamu kirim atau terima tampil di sini.',
                    )
                  : Column(
                      children: [
                        for (final b in h.items) ...[
                          AppCard(
                            onTap: () => context.push('/booking/${b.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.judulJob} · ${b.labelStatus}',
                                  style: context.text.h3,
                                ),
                                const SizedBox(height: AppSpace.s8),
                                ProfilBaris(profil: b.pihakLain),
                                const SizedBox(height: AppSpace.s8),
                                Text(
                                  'Upah disepakati: ${b.harga.teks}',
                                  style: context.text.bodySm,
                                ),
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

/// S-10 Detail ajuan: upah dan biaya terlihat sebelum Setujui (brief v2 T4); aksi dan akibat dari server.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider(id));
    return AppScaffold(
      title: booking.value?.judulJob ?? 'Ajuan',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: booking,
            onUlangi: () => ref.invalidate(bookingProvider(id)),
            isi: (b) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(b.labelStatus, style: context.text.h3),
                const SizedBox(height: AppSpace.s12),
                AppCard(child: ProfilBaris(profil: b.pihakLain)),
                const SizedBox(height: AppSpace.s12),
                BarisInfo('Upah disepakati', b.harga.teks),
                BarisInfo('Biaya admin', b.biayaAdmin.teks),
                BarisInfo(
                  'Persetujuan majikan',
                  b.majikanSetuju ? 'Sudah setuju' : 'Belum',
                ),
                BarisInfo(
                  'Persetujuan pekerja',
                  b.pekerjaSetuju ? 'Sudah setuju' : 'Belum',
                ),
                if (b.status == 'MENUNGGU_LOCK' && b.batasLock != null)
                  BarisInfo(
                    'Batas persetujuan',
                    '${formatDateTime(b.batasLock!.sampai)} (${b.batasLock!.teks})',
                  ),
                if (b.tagihanTeks != null) ...[
                  const SizedBox(height: AppSpace.s8),
                  AppCard(
                    color: context.tokens.warningContainer,
                    child: Text('Tagihan menunggu: ${b.tagihanTeks}'),
                  ),
                ],
                const SizedBox(height: AppSpace.s16),
                DaftarAksi(
                  aksi: b.aksi,
                  jalankan: (kode) async {
                    await ref
                        .read(apiClientProvider)
                        .post(
                          '/booking/${b.id}/${kode.toLowerCase()}',
                          options: ApiClient.idempotent(newIdempotencyKey()),
                        );
                    ref.invalidate(bookingProvider(id));
                    ref.invalidate(bookingDaftarProvider);
                  },
                ),
                if (b.percakapanId != null)
                  AppButton(
                    label: 'Buka chat',
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        context.push('/percakapan/${b.percakapanId}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
