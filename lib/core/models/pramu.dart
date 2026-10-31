import 'package:pramu_apps/core/api/api_client.dart' show Json;
import 'package:pramu_apps/core/time.dart';

export 'package:pramu_apps/core/api/api_client.dart' show Json;

/// Nominal dari server: angka untuk logika, teks sudah terformat sesuai bahasa (klien tidak memformat ulang).
class Uang {
  const Uang(this.nilai, this.teks);
  factory Uang.fromJson(Object? j) {
    final m = j as Json? ?? const {};
    return Uang((m['nilai'] as num?)?.toInt() ?? 0, m['teks'] as String? ?? '');
  }
  final int nilai;
  final String teks;
}

/// Batas waktu dari server; `teks` seperti "5 jam 12 menit lagi" sudah dalam bahasa pengguna.
class BatasWaktu {
  const BatasWaktu(this.sampai, this.teks);
  static BatasWaktu? fromJson(Object? j) {
    if (j is! Json) return null;
    return BatasWaktu(
      parseApiTime(j['sampai'] as String),
      j['teks'] as String? ?? '',
    );
  }

  final DateTime sampai;
  final String teks;
}

/// Aksi yang boleh dilakukan pengguna ini sekarang, dihitung server (brief v2 §8.3). Klien hanya menampilkan.
class Aksi {
  const Aksi({
    this.tersedia = const [],
    this.akibat = const {},
    this.alasanNonaktif = const {},
  });
  factory Aksi.fromJson(Json j) => Aksi(
    tersedia: [
      for (final a in j['aksi_tersedia'] as List? ?? const []) a as String,
    ],
    akibat: _peta(j['akibat']),
    alasanNonaktif: _peta(j['alasan_nonaktif']),
  );
  final List<String> tersedia;
  final Map<String, String> akibat;
  final Map<String, String> alasanNonaktif;

  static Map<String, String> _peta(Object? o) => o is Map
      ? {for (final e in o.entries) e.key as String: e.value.toString()}
      : const {};
}

/// `RingkasanProfil` (PRD §13): hanya data yang terbuka sebelum disepakati.
class RingkasanProfil {
  const RingkasanProfil({
    required this.id,
    required this.nama,
    this.fotoUrl,
    this.terverifikasi = false,
    this.rating,
    this.jumlahUlasan = 0,
    this.jumlahSelesai = 0,
    this.pembatalan120Hari = 0,
    this.badgePeringatan = false,
    this.laporanTerverifikasi = false,
    this.baru = false,
    this.kecamatan = '',
  });
  factory RingkasanProfil.fromJson(Json j) => RingkasanProfil(
    id: j['id'] as String,
    nama: j['nama'] as String? ?? '',
    fotoUrl: j['foto_url'] as String?,
    terverifikasi: j['terverifikasi'] as bool? ?? false,
    rating: (j['rating'] as num?)?.toDouble(),
    jumlahUlasan: (j['jumlah_ulasan'] as num?)?.toInt() ?? 0,
    jumlahSelesai: (j['jumlah_selesai'] as num?)?.toInt() ?? 0,
    pembatalan120Hari: (j['pembatalan_120_hari'] as num?)?.toInt() ?? 0,
    badgePeringatan: j['badge_peringatan'] as bool? ?? false,
    laporanTerverifikasi: j['laporan_terverifikasi'] as bool? ?? false,
    baru: j['baru'] as bool? ?? false,
    kecamatan: j['kecamatan'] as String? ?? '',
  );
  final String id;
  final String nama;
  final String? fotoUrl;
  final bool terverifikasi;
  final double? rating;
  final int jumlahUlasan;
  final int jumlahSelesai;
  final int pembatalan120Hari;
  final bool badgePeringatan;

  /// Ada laporan yang diputuskan admin benar (K-126); bukan sekadar pembatasan otomatis.
  final bool laporanTerverifikasi;
  final bool baru;
  final String kecamatan;
}

/// Peran akun di kawat API.
abstract final class Peran {
  static const majikan = 'MAJIKAN';
  static const pekerja = 'PEKERJA';
}
