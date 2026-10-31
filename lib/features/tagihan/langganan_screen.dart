import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/tagihan/langganan.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Langganan majikan (PRD §8): paket sekarang, kuota job aktif, beli atau perpanjang, dan upgrade dengan harga prorata.
/// Pembelian menghasilkan tagihan QRIS yang dibayar di layar Tagihan.
class LanggananScreen extends ConsumerStatefulWidget {
  const LanggananScreen({super.key});

  @override
  ConsumerState<LanggananScreen> createState() => _LanggananScreenState();
}

class _LanggananScreenState extends ConsumerState<LanggananScreen> {
  String? _proses;

  Future<void> _beli(Paket p, {required bool upgrade}) async {
    setState(() => _proses = p.id);
    try {
      final t =
          await ref
                  .read(apiClientProvider)
                  .post(
                    upgrade ? '/langganan/upgrade' : '/langganan',
                    data: {'paket_id': p.id},
                    options: ApiClient.idempotent(newIdempotencyKey()),
                  )
              as Json;
      ref.invalidate(langgananProvider);
      if (mounted) context.push('/tagihan/${t['id']}');
    } on ApiException catch (e) {
      if (mounted) AppSnack.show(context, pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = null);
    }
  }

  String _statusTeks(LanggananInfo l) {
    final sampai = l.berakhir == null
        ? ''
        : ' sampai ${formatDate(l.berakhir!)}';
    return switch (l.status) {
      'AKTIF' => 'Aktif$sampai',
      'TENGGANG' => 'Masa tenggang$sampai. Perpanjang agar job tetap tayang.',
      'MENUNGGU_PEMBAYARAN' =>
        'Menunggu pembayaran. Selesaikan di layar Tagihan.',
      _ => 'Belum berlangganan',
    };
  }

  @override
  Widget build(BuildContext context) {
    final langganan = ref.watch(langgananProvider);
    final paket = ref.watch(paketProvider);
    return AppScaffold(
      title: 'Langganan',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paketProvider);
          await ref.read(langgananProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: langganan,
              onUlangi: () => ref.invalidate(langgananProvider),
              isi: (l) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.paket?.nama ?? 'Tanpa paket',
                          style: context.text.h3,
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(_statusTeks(l), style: context.text.body),
                        const SizedBox(height: AppSpace.s8),
                        Text(
                          'Job aktif: ${l.jobAktif} dari ${l.batasJobAktif}',
                          style: context.text.bodySm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Text('Pilih paket', style: context.text.h3),
                  const SizedBox(height: AppSpace.s8),
                  Muat(
                    nilai: paket,
                    onUlangi: () => ref.invalidate(paketProvider),
                    isi: (daftar) => Column(
                      children: [
                        for (final p in daftar) ...[
                          _KartuPaket(
                            paket: p,
                            sekarang: l.paket?.id == p.id,
                            upgrade: l.aktif ? l.upgradeUntuk(p.id) : null,
                            sibuk: _proses == p.id,
                            onBeli: (up) => _beli(p, upgrade: up),
                          ),
                          const SizedBox(height: AppSpace.s12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuPaket extends StatelessWidget {
  const _KartuPaket({
    required this.paket,
    required this.sekarang,
    required this.upgrade,
    required this.sibuk,
    required this.onBeli,
  });

  final Paket paket;
  final bool sekarang;
  final OpsiUpgrade? upgrade;
  final bool sibuk;
  final void Function(bool upgrade) onBeli;

  @override
  Widget build(BuildContext context) {
    final bisaUpgrade = upgrade?.boleh ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${paket.nama} · ${paket.durasiBulan} bulan',
            style: context.text.h3,
          ),
          const SizedBox(height: AppSpace.s4),
          Text(paket.harga.teks, style: context.text.body),
          Text(
            'Sampai ${paket.batasJobAktif} job aktif sekaligus',
            style: context.text.bodySm,
          ),
          const SizedBox(height: AppSpace.s12),
          if (upgrade != null && !bisaUpgrade && upgrade!.alasan != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Text(upgrade!.alasan!, style: context.text.bodySm),
            ),
          AppButton(
            label: bisaUpgrade
                ? 'Upgrade, bayar ${upgrade!.bayar.teks}'
                : (sekarang ? 'Perpanjang' : 'Pilih paket'),
            loading: sibuk,
            expand: true,
            onPressed: sibuk || (upgrade != null && !bisaUpgrade && !sekarang)
                ? null
                : () => onBeli(bisaUpgrade),
          ),
        ],
      ),
    );
  }
}
