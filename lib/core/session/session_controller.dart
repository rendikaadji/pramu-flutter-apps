import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';

/// Bentuk `Akun`. Langkah onboarding dihitung server (brief v2 §5.1); klien hanya mengikuti.
class Akun {
  const Akun({
    required this.id,
    required this.peran,
    this.namaDepan,
    this.inisial,
    this.bahasa = 'id',
    this.statusVerifikasi = 'BELUM',
    this.langkahBerikutnya,
    this.langkahPerPeran = const {},
  });

  factory Akun.fromJson(Json j) => Akun(
    id: j['id'] as String,
    namaDepan: j['nama_depan'] as String?,
    inisial: j['inisial'] as String?,
    bahasa: j['bahasa'] as String? ?? 'id',
    peran: [for (final p in j['peran'] as List? ?? const []) p as String],
    statusVerifikasi: j['status_verifikasi'] as String? ?? 'BELUM',
    langkahBerikutnya: j['langkah_onboarding_berikutnya'] as String?,
    langkahPerPeran: {
      for (final e in (j['langkah_per_peran'] as Map? ?? const {}).entries)
        e.key as String: e.value as String?,
    },
  );

  final String id;
  final String? namaDepan;
  final String? inisial;
  final String bahasa;
  final List<String> peran;
  final String statusVerifikasi;

  /// Langkah yang menghalangi seluruh akun; null begitu ada satu peran siap.
  final String? langkahBerikutnya;

  /// Langkah per peran (null = peran siap). Menambah peran kedua tidak mengunci peran pertama.
  final Map<String, String?> langkahPerPeran;

  bool get onboardingSelesai => langkahBerikutnya == null;

  /// Langkah untuk [peran]: langkah akun dulu, lalu langkah khusus peran itu.
  String? langkahUntuk(String? peran) =>
      langkahBerikutnya ?? (peran == null ? null : langkahPerPeran[peran]);

  /// Peran pertama yang sudah siap dipakai, bila ada.
  String? get peranSiap => [
    for (final p in peran)
      if (langkahPerPeran.containsKey(p) && langkahPerPeran[p] == null) p,
  ].firstOrNull;
  String get nama => [namaDepan, inisial].whereType<String>().join(' ').trim();
}

/// Sesi: token di [TokenStore], akun dari GET /me. `null` = belum masuk.
class SessionController extends AsyncNotifier<Akun?> {
  @override
  Future<Akun?> build() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null) return null;
    try {
      return await _ambilAkun();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ref.read(tokenStoreProvider).clear();
        return null;
      }
      rethrow;
    }
  }

  Future<Akun> _ambilAkun() async =>
      Akun.fromJson(await ref.read(apiClientProvider).get('/me') as Json);

  /// Setelah OTP terverifikasi: simpan token, pakai akun dari respons.
  Future<void> masuk(String token, Json akun) async {
    await ref.read(tokenStoreProvider).write(token);
    state = AsyncData(Akun.fromJson(akun));
  }

  /// Muat ulang akun (mis. setelah persetujuan atau tambah peran) agar router mengikuti langkah berikutnya.
  Future<void> muatUlang() async {
    state = AsyncData(await _ambilAkun());
  }

  void ganti(Akun akun) => state = AsyncData(akun);

  Future<void> keluar() async {
    try {
      await ref.read(apiClientProvider).post('/auth/keluar');
    } on ApiException {
      // Token mungkin sudah tidak berlaku; tetap keluar di perangkat.
    }
    await _hapus();
  }

  /// Dipanggil ApiClient saat server menolak token (401).
  Future<void> tokenDitolak() => _hapus();

  Future<void> _hapus() async {
    await ref.read(tokenStoreProvider).clear();
    await ref.read(prefsProvider).remove(_kunciPeran);
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, Akun?>(
  SessionController.new,
);

const _kunciPeran = 'peran_aktif';

/// Peran yang sedang dipakai (akun bisa majikan dan pekerja sekaligus, PRD §3.1). Disimpan per perangkat.
class PeranAktif extends Notifier<String?> {
  @override
  String? build() {
    final akun = ref.watch(sessionProvider).value;
    if (akun == null || akun.peran.isEmpty) return null;
    final simpan = ref.read(prefsProvider).getString(_kunciPeran);
    // Tanpa pilihan tersimpan, pakai peran yang sudah siap agar peran baru yang belum lengkap tidak mengunci akun.
    return akun.peran.contains(simpan)
        ? simpan
        : akun.peranSiap ?? akun.peran.first;
  }

  void pilih(String peran) {
    ref.read(prefsProvider).setString(_kunciPeran, peran);
    state = peran;
  }
}

final peranAktifProvider = NotifierProvider<PeranAktif, String?>(
  PeranAktif.new,
);
