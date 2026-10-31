import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:pramu_apps/shared/muat.dart';

/// S-20 Akun: ganti peran aktif, ajak tetangga lewat WhatsApp (K-131), dan keluar.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

  // Tautan hanya membawa kode wilayah pengundang, tanpa identitas siapa pun; pesan siap kirim dari server.
  Future<void> _ajak(BuildContext context, WidgetRef ref) async {
    try {
      final u = await ref.read(apiClientProvider).get('/me/undangan') as Json;
      final ok = await openWhatsAppUrl(
        ref.read(urlLauncherProvider),
        u['tautan_wa'] as String,
      );
      if (!ok && context.mounted) {
        AppSnack.show(context, 'WhatsApp tidak bisa dibuka.');
      }
    } on ApiException catch (e) {
      if (context.mounted) AppSnack.show(context, pesanGalat(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final akun = ref.watch(sessionProvider).value;
    final aktif = ref.watch(peranAktifProvider);
    if (akun == null) return const SizedBox.shrink();
    const nama = {Peran.majikan: 'Majikan', Peran.pekerja: 'Pekerja'};

    return AppScaffold(
      title: 'Akun',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            akun.nama.isEmpty ? 'Akun Pramu' : akun.nama,
            style: context.text.h1,
          ),
          Text(
            akun.statusVerifikasi == 'TERVERIFIKASI'
                ? 'KTP terverifikasi'
                : 'KTP belum terverifikasi',
            style: context.text.bodySm,
          ),
          const SizedBox(height: AppSpace.s24),
          if (akun.peran.length > 1) ...[
            Text('Peran aktif', style: context.text.h3),
            const SizedBox(height: AppSpace.s8),
            SegmentedButton<String>(
              segments: [
                for (final p in akun.peran)
                  ButtonSegment(value: p, label: Text(nama[p] ?? p)),
              ],
              selected: {?aktif},
              onSelectionChanged: (s) =>
                  ref.read(peranAktifProvider.notifier).pilih(s.first),
            ),
            const SizedBox(height: AppSpace.s24),
          ],
          ListTileCard(
            children: [
              SettingsRow(
                icon: LucideIcons.share2,
                title: 'Ajak tetangga lewat WhatsApp',
                subtitle: 'Makin banyak yang bergabung, makin mudah menemukan yang cocok.',
                onTap: () => _ajak(context, ref),
              ),
              SettingsRow(
                icon: LucideIcons.receipt,
                title: 'Tagihan dan pembayaran',
                subtitle: 'Bayar lewat QRIS dan lihat bukti bayar.',
                onTap: () => context.push('/tagihan'),
              ),
              SettingsRow(
                icon: LucideIcons.smartphone,
                title: 'Ganti nomor HP',
                subtitle:
                    'Bukti lewat WhatsApp dari nomor sekarang dan nomor baru.',
                onTap: () => context.push('/akun/nomor'),
              ),
              SettingsRow(
                key: K.logout,
                icon: LucideIcons.logOut,
                title: 'Keluar',
                destructive: true,
                onTap: () async {
                  final ok = await ConfirmDialog.show(
                    context,
                    title: 'Keluar?',
                    message: 'Kamu perlu kode WhatsApp lagi untuk masuk.',
                    confirmLabel: 'Keluar',
                  );
                  if (ok) await ref.read(sessionProvider.notifier).keluar();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
