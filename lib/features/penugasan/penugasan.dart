import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';

/// Bentuk `Penugasan` (pekerjaan yang sudah disepakati) untuk satu pihak.
class Penugasan {
  const Penugasan({
    required this.id,
    required this.judul,
    required this.pihakLain,
    required this.labelStatus,
    required this.aksi,
    this.harga,
    this.hariKe,
    this.tanggalBerakhir,
    this.batasKonfirmasi,
    this.alamat,
    this.petaUrl,
    this.percakapanId,
  });

  factory Penugasan.fromJson(Json j) => Penugasan(
    id: j['id'] as String,
    judul: j['judul'] as String,
    pihakLain: RingkasanProfil.fromJson(j['pihak_lain'] as Json),
    labelStatus: j['label_status'] as String? ?? '',
    harga: j['harga_kesepakatan'] == null
        ? null
        : Uang.fromJson(j['harga_kesepakatan']),
    hariKe: (j['hari_ke'] as num?)?.toInt(),
    tanggalBerakhir: j['tanggal_efektif_berakhir'] as String?,
    batasKonfirmasi: BatasWaktu.fromJson(j['batas_konfirmasi']),
    alamat: j['alamat'] as String?,
    petaUrl: j['peta_url'] as String?,
    percakapanId: j['percakapan_id'] as String?,
    aksi: Aksi.fromJson(j),
  );

  final String id;
  final String judul;
  final RingkasanProfil pihakLain;
  final String labelStatus;
  final Uang? harga;
  final int? hariKe;
  final String? tanggalBerakhir;
  final BatasWaktu? batasKonfirmasi;
  final String? alamat;
  final String? petaUrl;
  final String? percakapanId;
  final Aksi aksi;
}

const alasanBatal = {
  'BERHALANGAN': 'Berhalangan',
  'SAKIT': 'Sakit',
  'JADWAL_BENTROK': 'Jadwal bentrok',
  'TIDAK_SESUAI_KESEPAKATAN': 'Tidak sesuai kesepakatan',
  'LAINNYA': 'Lainnya',
};

final penugasanDaftarProvider = FutureProvider.autoDispose<Paged<Penugasan>>((
  ref,
) {
  final peran = ref.watch(peranAktifProvider);
  return ref
      .watch(apiClientProvider)
      .getPage('/penugasan', Penugasan.fromJson, query: {'peran': peran});
});

final penugasanProvider = FutureProvider.autoDispose.family<Penugasan, String>(
  (ref, id) async => Penugasan.fromJson(
    await ref.watch(apiClientProvider).get('/penugasan/$id') as Json,
  ),
);
