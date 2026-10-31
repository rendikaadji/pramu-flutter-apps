import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/features/tagihan/tagihan.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:qr_flutter/qr_flutter.dart';

StatusChip _chip(String status) => switch (status) {
  'LUNAS' => const StatusChip(label: 'Lunas', tone: StatusTone.success),
  'KEDALUWARSA' => const StatusChip(
    label: 'Kedaluwarsa',
    tone: StatusTone.neutral,
  ),
  'DISANGGAH' => const StatusChip(
    label: 'Sedang disanggah',
    tone: StatusTone.info,
  ),
  _ => const StatusChip(label: 'Menunggu bayar', tone: StatusTone.warning),
};

/// Daftar tagihan dan riwayat bayar.
class TagihanDaftarScreen extends ConsumerWidget {
  const TagihanDaftarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(tagihanDaftarProvider);
    return AppScaffold(
      title: 'Tagihan',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tagihanDaftarProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: daftar,
              onUlangi: () => ref.invalidate(tagihanDaftarProvider),
              isi: (h) => h.items.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada tagihan',
                      message: 'Tagihan dan bukti bayar tampil di sini.',
                    )
                  : Column(
                      children: [
                        for (final t in h.items) ...[
                          AppCard(
                            onTap: () => context.push('/tagihan/${t.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.judul, style: context.text.h3),
                                const SizedBox(height: AppSpace.s4),
                                Text(t.nominal.teks, style: context.text.body),
                                const SizedBox(height: AppSpace.s8),
                                _chip(t.status),
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

/// S-11 Detail tagihan: QRIS untuk dipindai dari aplikasi bank atau dompet digital. Status diperiksa berkala sampai lunas.
class TagihanDetailScreen extends ConsumerStatefulWidget {
  const TagihanDetailScreen({
    super.key,
    required this.id,
    this.intervalPeriksa = const Duration(seconds: 5),
  });

  final String id;
  final Duration intervalPeriksa;

  @override
  ConsumerState<TagihanDetailScreen> createState() => _TagihanDetailState();
}

class _TagihanDetailState extends ConsumerState<TagihanDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.intervalPeriksa, (_) {
      if (ref.read(tagihanProvider(widget.id)).value?.menunggu ?? false) {
        ref.invalidate(tagihanProvider(widget.id));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nilai = ref.watch(tagihanProvider(widget.id));
    return AppScaffold(
      title: 'Bayar tagihan',
      scrollable: true,
      body: Muat(
        nilai: nilai,
        onUlangi: () => ref.invalidate(tagihanProvider(widget.id)),
        isi: (t) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.judul, style: context.text.h2),
            const SizedBox(height: AppSpace.s4),
            Text(t.nominal.teks, style: context.text.h1),
            const SizedBox(height: AppSpace.s8),
            Align(alignment: Alignment.centerLeft, child: _chip(t.status)),
            const SizedBox(height: AppSpace.s16),
            if (t.menunggu && t.qrPayload != null) ...[
              Center(
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s12),
                    child: QrImageView(
                      data: t.qrPayload!,
                      size: 240,
                      semanticsLabel: 'Kode QRIS untuk ${t.nominal.teks}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                'Buka aplikasi bank atau dompet digital, pilih bayar dengan QRIS, lalu pindai kode ini. Halaman ini berubah sendiri begitu pembayaran masuk.',
                style: context.text.body,
              ),
              if (t.berlakuSampai != null) ...[
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Kode berlaku ${t.berlakuSampai!.teks}.',
                  style: context.text.bodySm,
                ),
              ],
              if (t.nominalJikaTerlambat != null) ...[
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Setelah batas diskon, nominalnya menjadi ${t.nominalJikaTerlambat!.teks}.',
                  style: context.text.bodySm,
                ),
              ],
            ] else if (t.status == 'LUNAS') ...[
              Text(
                'Pembayaran sudah kami terima. Terima kasih.',
                style: context.text.body,
              ),
              if (t.referensi != null) ...[
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Nomor referensi: ${t.referensi}',
                  style: context.text.bodySm,
                ),
              ],
            ] else if (t.status == 'KEDALUWARSA')
              Text(
                'Kode ini sudah kedaluwarsa. Buka tagihannya lagi dari layar sebelumnya untuk mendapat kode baru.',
                style: context.text.body,
              ),
            const SizedBox(height: AppSpace.s24),
            AppButton(
              label: 'Kembali',
              expand: true,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
