import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Kartu terbatas untuk akun yang belum KTP (PRD §7.7, K-113): tanpa id, nama, foto, kecamatan, atau kontak.
class KartuTerbatas {
  const KartuTerbatas({
    required this.kategori,
    required this.kelompokJarak,
    required this.rating,
    required this.jumlahUlasan,
    required this.jumlahSelesai,
    required this.baru,
    required this.ongkosDitanggung,
  });

  factory KartuTerbatas.fromJson(Json j) => KartuTerbatas(
    kategori: (j['kategori'] as Json)['nama'] as String,
    kelompokJarak: j['kelompok_jarak'] as String?,
    rating: (j['rating'] as num?)?.toDouble(),
    jumlahUlasan: (j['jumlah_ulasan'] as num?)?.toInt() ?? 0,
    jumlahSelesai: (j['jumlah_selesai'] as num?)?.toInt() ?? 0,
    baru: j['baru'] as bool? ?? true,
    ongkosDitanggung: j['ongkos_ditanggung'] as String?,
  );

  final String kategori;
  final String? kelompokJarak;
  final double? rating;
  final int jumlahUlasan;
  final int jumlahSelesai;
  final bool baru;
  final String? ongkosDitanggung;
}

/// `peran` = peran yang dicari: MAJIKAN melihat pekerja, PEKERJA melihat job. `lebihJauh` memperluas jarak (K-115).
final jelajahProvider = FutureProvider.autoDispose
    .family<Paged<KartuTerbatas>, ({String peran, bool lebihJauh})>(
      (ref, k) => ref
          .watch(apiClientProvider)
          .getPage(
            '/jelajah',
            KartuTerbatas.fromJson,
            query: {'peran': k.peran, if (k.lebihJauh) 'lebih_jauh': 'true'},
          ),
    );

class JelajahScreen extends ConsumerStatefulWidget {
  const JelajahScreen({super.key});

  @override
  ConsumerState<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends ConsumerState<JelajahScreen> {
  String _peran = Peran.majikan;
  bool _lebihJauh = false;

  @override
  Widget build(BuildContext context) {
    final kunci = (peran: _peran, lebihJauh: _lebihJauh);
    final daftar = ref.watch(jelajahProvider(kunci));
    return AppScaffold(
      title: 'Lihat dulu',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Text(
            'Lihat gambaran pekerja dan pekerjaan di sekitarmu sebelum melengkapi data. Nama, foto, dan kontak baru terbuka setelah KTP terverifikasi dan kalian sepakat.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s12),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final (p, label) in [
                (Peran.majikan, 'Saya mencari pekerja'),
                (Peran.pekerja, 'Saya mencari pekerjaan'),
              ])
                AppButton(
                  label: label,
                  expand: false,
                  variant: _peran == p
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _peran = p;
                    _lebihJauh = false;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Muat(
            nilai: daftar,
            onUlangi: () => ref.invalidate(jelajahProvider(kunci)),
            isi: (h) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (h.extra['sisa_hari_ini'] != null)
                  Text(
                    'Sisa kartu yang bisa dilihat hari ini: ${h.extra['sisa_hari_ini']}',
                    style: context.text.caption,
                  ),
                if (h.items.isEmpty)
                  const EmptyState(
                    title: 'Belum ada',
                    message: 'Belum ada yang cocok di sekitarmu.',
                  )
                else
                  for (final k in h.items) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.kategori, style: context.text.h3),
                          Text(_ringkas(k), style: context.text.bodySm),
                          if (k.ongkosDitanggung != null)
                            Text(
                              kalimatOngkos(k.ongkosDitanggung!),
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
          if (!_lebihJauh)
            AppButton(
              label: 'Lihat lebih jauh',
              variant: AppButtonVariant.secondary,
              onPressed: () => setState(() => _lebihJauh = true),
            )
          else
            Text(
              'Menampilkan sampai jarak terjauh yang diizinkan untuk jenis pekerjaan ini.',
              style: context.text.bodySm,
            ),
          const SizedBox(height: AppSpace.s16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingin mengajukan atau menerima?', style: context.text.h3),
                Text(
                  'Lengkapi verifikasi KTP dulu. Data pribadimu tidak pernah tampil ke orang lain sebelum kalian sepakat.',
                  style: context.text.bodySm,
                ),
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  label: 'Lengkapi data',
                  onPressed: () => context.go('/lanjutkan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _ringkas(KartuTerbatas k) => [
    if (k.kelompokJarak != null) '${k.kelompokJarak} km',
    if (k.baru) 'Baru' else '${k.rating} dari ${k.jumlahUlasan} ulasan',
    '${k.jumlahSelesai} pekerjaan selesai',
  ].join(' · ');
}
