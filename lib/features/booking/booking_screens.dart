import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/booking.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/batas_chip.dart';
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

/// S-10 Detail ajuan: upah, siapa membayar biaya admin, dan status persetujuan terlihat sebelum Setujui (brief §7.6).
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider(id));
    final peran = ref.watch(peranAktifProvider);
    return AppScaffold(
      title: booking.value == null
          ? 'Ajuan'
          : 'Ajuan ${booking.value!.judulJob}',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: booking,
            onUlangi: () => ref.invalidate(bookingProvider(id)),
            isi: (b) {
              final saya = peran == Peran.majikan
                  ? b.majikanSetuju
                  : b.pekerjaSetuju;
              final lain = peran == Peran.majikan
                  ? b.pekerjaSetuju
                  : b.majikanSetuju;
              final sayaMembayar =
                  b.penanggungBiaya == peran && b.biayaAdmin.nilai > 0;
              final pembayar = b.penanggungBiaya == peran
                  ? 'kamu'
                  : b.penanggungBiaya == Peran.majikan
                  ? 'majikan'
                  : 'pekerja';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(b.labelStatus, style: context.text.h3),
                  if (b.status == 'MENUNGGU_LOCK' && b.batasLock != null) ...[
                    const SizedBox(height: AppSpace.s8),
                    BatasChip(b.batasLock!, label: 'Kedaluwarsa dalam'),
                  ],
                  const SizedBox(height: AppSpace.s12),
                  AppCard(child: ProfilBaris(profil: b.pihakLain)),
                  const SizedBox(height: AppSpace.s12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upah yang disepakati',
                          style: context.text.bodySm,
                        ),
                        Text(b.harga.teks, style: context.text.h2),
                        // Pekerjaan sekali datang tidak punya biaya admin (penanggung_biaya null).
                        if (b.penanggungBiaya != null) ...[
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'Biaya admin ${b.biayaAdmin.teks} dibayar oleh $pembayar saat kedua pihak setuju.',
                            style: context.text.body,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Persetujuan', style: context.text.bodySm),
                        const SizedBox(height: AppSpace.s4),
                        _Langkah(
                          selesai: lain,
                          teks: lain
                              ? '${b.pihakLain.nama} sudah setuju'
                              : '${b.pihakLain.nama} belum setuju',
                        ),
                        _Langkah(
                          selesai: saya,
                          teks: saya
                              ? 'Kamu sudah setuju'
                              : 'Kamu belum setuju',
                        ),
                      ],
                    ),
                  ),
                  if (b.status == 'MENUNGGU_LOCK') ...[
                    const SizedBox(height: AppSpace.s12),
                    const BarisTerkunci('Alamat, foto rumah, dan kontak'),
                  ],
                  if (b.tagihanTeks != null) ...[
                    const SizedBox(height: AppSpace.s12),
                    AppCard(
                      color: context.tokens.warningContainer,
                      child: Text('Tagihan menunggu: ${b.tagihanTeks}'),
                    ),
                  ],
                  const SizedBox(height: AppSpace.s16),
                  DaftarAksi(
                    aksi: b.aksi,
                    label: {
                      if (sayaMembayar)
                        'SETUJUI': 'Setujui dan bayar ${b.biayaAdmin.teks}',
                    },
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
                      label: 'Pesan',
                      icon: LucideIcons.messageCircle,
                      variant: AppButtonVariant.text,
                      onPressed: () =>
                          context.push('/percakapan/${b.percakapanId}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Satu baris status persetujuan (brief §10 ApprovalSteps).
class _Langkah extends StatelessWidget {
  const _Langkah({required this.selesai, required this.teks});

  final bool selesai;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
    child: Row(
      children: [
        Icon(
          selesai ? LucideIcons.circleCheck : LucideIcons.circle,
          size: 20,
          color: selesai ? context.tokens.success : context.tokens.textMuted,
        ),
        const SizedBox(width: AppSpace.s8),
        Expanded(child: Text(teks, style: context.text.body)),
      ],
    ),
  );
}
