import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';

/// Bentuk `Kategori`.
class Kategori {
  const Kategori({
    required this.id,
    required this.nama,
    required this.tipe,
    this.namaBebas = false,
    this.kelipatanTitik = 1,
  });
  factory Kategori.fromJson(Json j) => Kategori(
    id: j['id'] as String,
    nama: j['nama'] as String,
    tipe: j['tipe'] as String,
    namaBebas: j['nama_bebas'] as bool? ?? false,
    kelipatanTitik: (j['kelipatan_titik'] as num?)?.toInt() ?? 1,
  );
  final String id;
  final String nama;
  final String tipe; // PERIODIK | INSIDENTAL
  final bool namaBebas;
  final int kelipatanTitik;
  bool get periodik => tipe == 'PERIODIK';
}

/// Bentuk `Job` (milik majikan).
class Job {
  const Job({
    required this.id,
    required this.judul,
    required this.status,
    required this.kisaran,
    required this.mulaiKerja,
    required this.aksi,
    this.deskripsi,
    this.kecamatan = '',
    this.jumlahAjuanMenunggu = 0,
  });
  factory Job.fromJson(Json j) => Job(
    id: j['id'] as String,
    judul: j['judul'] as String,
    status: j['status'] as String,
    kisaran: j['kisaran'] as String? ?? '',
    mulaiKerja: parseApiTime(j['mulai_kerja'] as String),
    deskripsi: j['deskripsi'] as String?,
    kecamatan: j['kecamatan'] as String? ?? '',
    jumlahAjuanMenunggu: (j['jumlah_ajuan_menunggu'] as num?)?.toInt() ?? 0,
    aksi: Aksi.fromJson(j),
  );
  final String id;
  final String judul;
  final String status;
  final String kisaran;
  final DateTime mulaiKerja;
  final String? deskripsi;
  final String kecamatan;
  final int jumlahAjuanMenunggu;
  final Aksi aksi;
}

const labelStatusJob = {
  'TERBUKA': 'Terbuka',
  'TERISI': 'Terisi',
  'SELESAI': 'Selesai',
  'TUTUP': 'Ditutup',
};

/// Bentuk `Kandidat` (pekerja yang cocok untuk job majikan).
class Kandidat {
  const Kandidat({
    required this.profil,
    required this.kelompokJarak,
    required this.upah,
  });
  factory Kandidat.fromJson(Json j) => Kandidat(
    profil: RingkasanProfil.fromJson(j['profil'] as Json),
    kelompokJarak: j['kelompok_jarak'] as String? ?? '',
    upah: j['upah_di_kisaranmu'] as String? ?? '',
  );
  final RingkasanProfil profil;
  final String kelompokJarak;
  final String upah;
}

/// Bentuk `KartuJob` (hasil cari job untuk pekerja).
class KartuJob {
  const KartuJob({
    required this.id,
    required this.judul,
    required this.labelTipe,
    required this.kecamatan,
    required this.kelompokJarak,
    required this.mulaiKerja,
    required this.upah,
    required this.majikan,
    this.kamuMembayar,
  });
  factory KartuJob.fromJson(Json j) => KartuJob(
    id: j['id'] as String,
    judul: j['judul'] as String,
    labelTipe: j['label_tipe'] as String? ?? '',
    kecamatan: j['kecamatan'] as String? ?? '',
    kelompokJarak: j['kelompok_jarak'] as String? ?? '',
    mulaiKerja: parseApiTime(j['mulai_kerja'] as String),
    upah: j['upah_di_kisaranmu'] as String? ?? '',
    kamuMembayar: j['penanggung_biaya_kamu'] as bool?,
    majikan: RingkasanProfil.fromJson(j['majikan'] as Json),
  );
  final String id;
  final String judul;
  final String labelTipe;
  final String kecamatan;
  final String kelompokJarak;
  final DateTime mulaiKerja;
  final String upah;
  final bool? kamuMembayar;
  final RingkasanProfil majikan;
}

final kategoriProvider = FutureProvider<List<Kategori>>((ref) async {
  final data = await ref.watch(apiClientProvider).get('/kategori') as List;
  return [for (final k in data) Kategori.fromJson(k as Json)];
});

final jobSayaProvider = FutureProvider.autoDispose<Paged<Job>>(
  (ref) => ref.watch(apiClientProvider).getPage('/me/job', Job.fromJson),
);

final jobProvider = FutureProvider.autoDispose.family<Job, String>(
  (ref, id) async =>
      Job.fromJson(await ref.watch(apiClientProvider).get('/job/$id') as Json),
);

/// `lebihJauh` memperluas jarak dari batas pertama ke maksimum jenis job (PRD §9.5, K-115); tidak disimpan.
final kandidatProvider = FutureProvider.autoDispose
    .family<Paged<Kandidat>, ({String id, bool lebihJauh})>(
      (ref, k) => ref
          .watch(apiClientProvider)
          .getPage(
            '/job/${k.id}/kandidat',
            Kandidat.fromJson,
            query: {if (k.lebihJauh) 'lebih_jauh': 'true'},
          ),
    );

final cariJobProvider = FutureProvider.autoDispose
    .family<Paged<KartuJob>, bool>(
      (ref, lebihJauh) => ref
          .watch(apiClientProvider)
          .getPage(
            '/job',
            KartuJob.fromJson,
            query: {if (lebihJauh) 'lebih_jauh': 'true'},
          ),
    );
