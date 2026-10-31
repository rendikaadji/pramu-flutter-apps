import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';

/// Bentuk `Booking` (ajuan) untuk satu pihak. Label, aksi, dan batas waktu dihitung server.
class Booking {
  const Booking({
    required this.id,
    required this.judulJob,
    required this.pihakLain,
    required this.status,
    required this.labelStatus,
    required this.harga,
    required this.biayaAdmin,
    required this.aksi,
    this.majikanSetuju = false,
    this.pekerjaSetuju = false,
    this.batasLock,
    this.tagihanTeks,
    this.percakapanId,
    this.penanggungBiaya,
    this.gratisPerkenalan = false,
  });

  factory Booking.fromJson(Json j) {
    final setuju = j['persetujuan'] as Json? ?? const {};
    final tagihan = j['tagihan_menunggu'] as Json?;
    return Booking(
      id: j['id'] as String,
      judulJob: (j['job'] as Json)['judul'] as String,
      pihakLain: RingkasanProfil.fromJson(j['pihak_lain'] as Json),
      status: j['status'] as String,
      labelStatus: j['label_status'] as String? ?? '',
      harga: Uang.fromJson(j['harga_kesepakatan']),
      biayaAdmin: Uang.fromJson(j['biaya_admin']),
      majikanSetuju: setuju['majikan_at'] != null,
      pekerjaSetuju: setuju['pekerja_at'] != null,
      batasLock: BatasWaktu.fromJson(j['batas_lock']),
      tagihanTeks: tagihan == null
          ? null
          : '${tagihan['judul']}: ${Uang.fromJson(tagihan['nominal']).teks}',
      percakapanId: j['percakapan_id'] as String?,
      penanggungBiaya: j['penanggung_biaya'] as String?,
      gratisPerkenalan: j['gratis_perkenalan'] as bool? ?? false,
      aksi: Aksi.fromJson(j),
    );
  }

  final String id;
  final String judulJob;
  final RingkasanProfil pihakLain;
  final String status;
  final String labelStatus;
  final Uang harga;
  final Uang biayaAdmin;
  final bool majikanSetuju;
  final bool pekerjaSetuju;
  final BatasWaktu? batasLock;
  final String? tagihanTeks;
  final String? percakapanId;

  /// Biaya admin digratiskan oleh jatah pertama pekerja selama masa perkenalan (K-123).
  final bool gratisPerkenalan;

  /// MAJIKAN atau PEKERJA untuk pekerjaan rutin; null untuk sekali datang (tanpa biaya admin).
  final String? penanggungBiaya;
  final Aksi aksi;
}

final bookingDaftarProvider = FutureProvider.autoDispose<Paged<Booking>>((ref) {
  final peran = ref.watch(peranAktifProvider);
  return ref
      .watch(apiClientProvider)
      .getPage('/booking', Booking.fromJson, query: {'peran': peran});
});

final bookingProvider = FutureProvider.autoDispose.family<Booking, String>(
  (ref, id) async => Booking.fromJson(
    await ref.watch(apiClientProvider).get('/booking/$id') as Json,
  ),
);
