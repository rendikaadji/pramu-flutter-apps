import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/features/profil/profil.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

/// Profil calon pekerja atau majikan. Nama, foto, dan kontak baru terbuka setelah KTP terverifikasi dan kedua pihak
/// sepakat; bidang yang masih terkunci dijelaskan, bukan disembunyikan diam-diam (PRD §13).
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key, required this.id, this.jobId});

  final String id;
  final String? jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kunci = (id: id, jobId: jobId);
    final profil = ref.watch(profilProvider(kunci));
    final ulasan = ref.watch(ulasanProfilProvider(id));
    return AppScaffold(
      title: 'Profil',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: profil,
            onUlangi: () => ref.invalidate(profilProvider(kunci)),
            isi: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(child: ProfilBaris(profil: p.ringkasan)),
                if (p.keahlian != null && p.keahlian!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s12),
                  Text('Keahlian', style: context.text.h3),
                  const SizedBox(height: AppSpace.s4),
                  Text(p.keahlian!, style: context.text.body),
                ],
                if (p.terkunci.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s12),
                  Text(
                    'Sebagian data baru terbuka setelah kalian berdua sepakat. Ini menjaga privasi kedua pihak.',
                    style: context.text.bodySm,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Ulasan', style: context.text.h2),
          const SizedBox(height: AppSpace.s8),
          Muat(
            nilai: ulasan,
            onUlangi: () => ref.invalidate(ulasanProfilProvider(id)),
            isi: (h) => h.items.isEmpty
                ? Text('Belum ada ulasan.', style: context.text.bodySm)
                : Column(
                    children: [
                      for (final u in h.items) ...[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RatingStars(value: u.bintang.toDouble()),
                              if (u.catatan != null &&
                                  u.catatan!.isNotEmpty) ...[
                                const SizedBox(height: AppSpace.s4),
                                Text(u.catatan!, style: context.text.body),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.s8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
