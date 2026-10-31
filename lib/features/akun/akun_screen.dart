import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// S-20 Akun: ganti peran aktif dan keluar.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

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
