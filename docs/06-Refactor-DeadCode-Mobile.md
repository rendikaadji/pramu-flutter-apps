---
tags: [proyek, mobile, flutter, refactor, dead-code, lint]
status: draft
tanggal: 2026-10-09
versi: 1.0
---

# 06 — Refactor & Dead Code (Flutter)

> **Perubahan lingkup 2026-10-28:** penampungan dana (escrow) dihapus: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, potongan platform 10%, dan sengketa dana **tidak berlaku lagi** (layar M-74..76, M-80..83). Kesepakatan, kontrak (tanpa uang), biaya tayang lowongan, dan rating tetap. Acuan terbaru: [[01-PRD-Mobile]] dan [[09-Arsitektur-App]].

> Prosedur aman, berlaku setelah repo `asisten-mobile` ada. Belum ada kode → belum ada temuan nyata; dokumen ini = playbook + target arsitektur dari [[Spec-Teknis-v1]]. Konteks: [[01-PRD-Mobile]]. 🟡 = verifikasi tool/versi di proyek.
> Prinsip: tidak ada refactor tanpa **test hijau sebelum** dan **sesudah**; satu perubahan kecil per commit ([[07-Git-Commit-Mobile]]).

## 1. Prosedur inti

```
baseline hijau  ->  deteksi  ->  hapus/ubah KECIL  ->  analyze+test  ->  bandingkan ukuran  ->  commit
      ^_______________________________ulangi per batch_______________________________|
```

| # | Langkah | Perintah / aksi |
|---|---|---|
| 0 | Branch bersih | `git switch -c refactor/<topik> develop` ; `git status` bersih |
| 1 | Baseline | `flutter pub get` · `flutter analyze` · `flutter test` · catat hasil (jumlah warning, durasi) |
| 2 | Baseline ukuran | `flutter build apk --release --analyze-size --target-platform android-arm64` (simpan angka + file `*-code-size-analysis_*.json`) · opsional `flutter build appbundle --release` |
| 3 | Auto-fix aman | `dart fix --dry-run` (lihat dulu) → `dart fix --apply` → `dart format .` → test lagi, commit terpisah (`style`/`refactor`) |
| 4 | Deteksi (§3) | Jalankan tool, **kandidat saja** — verifikasi manual |
| 5 | Hapus kecil | Satu file/aset/dependency per commit; urut: import tak terpakai → fungsi privat → file → aset → dependency |
| 6 | Verifikasi | `flutter analyze` · `flutter test` · jalankan app (debug) layar terkait · `integration_test` bila menyentuh alur kritis |
| 7 | Ukuran akhir | ulangi langkah 2; bandingkan (§6) |
| 8 | PR | checklist §8 |

Stop-rule: test merah setelah langkah hapus → `git restore` / revert commit itu, jangan "perbaiki sambil jalan".

## 2. Lint & analyzer

`analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml     # default template Flutter (flutter_lints)
# ATAU yang lebih ketat 🟡: include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/generated/**"
  errors:
    unused_import: warning
linter:
  rules:
    # unused_import/unused_element = diagnostic analyzer, aktif default (bukan linter rule)
    - directives_ordering
    - prefer_const_constructors
    - avoid_print
```
| Opsi | Catatan |
|---|---|
| `flutter_lints` | Bawaan template (`flutter create`), longgar, cocok mulai |
| `very_good_analysis` 🟡 | Lebih ketat (banyak rule `public_member_api_docs` dll.); mungkin berisik di proyek 3 minggu → pertimbangkan nonaktifkan rule dokumentasi |
| `avoid_print` | Mencegah `print` token/PII (selaras debug playbook) |
Jadikan `flutter analyze` **fatal di CI** (`--fatal-infos` opsional 🟡). Jangan menambah `// ignore:` tanpa alasan.

## 3. Deteksi kode/aset/dependency tak terpakai

| Target | Tool (verifikasi!) | Perintah | Catatan |
|---|---|---|---|
| Import, variabel lokal, elemen privat tak terpakai | Analyzer bawaan | `flutter analyze` (`unused_import`, `unused_local_variable`, `unused_element`, `unused_field`) | Paling aman, otoritatif |
| Fix otomatis lint | `dart fix` | `dart fix --dry-run` → `dart fix --apply` | Bawaan Dart SDK |
| Dependency di `pubspec.yaml` tak dipakai / tak dideklarasi | `dependency_validator` (pub.dev) 🟡 | `dart pub add --dev dependency_validator` lalu `dart run dependency_validator` | Konfigurasi ignore di `dependency_validator.yaml` untuk paket yang dipakai tidak langsung (mis. plugin native, `flutter_launcher_icons`, `build_runner`) |
| Dependency tree / siapa menarik paket | Pub | `flutter pub deps --style=compact` ; `dart pub deps -s list` ; `flutter pub outdated` | Untuk analisis transitif |
| File (`.dart`) tak diimpor siapa pun, kode publik tak terpakai | `dart_code_linter` (komunitas, fork dart_code_metrics) 🟡 / DCM (komersial) 🟡 | `dart run dart_code_linter:metrics check-unused-files lib` · `check-unused-code lib` | **Status pemeliharaan harus diverifikasi** sebelum adopsi; false positive pada entry point, route, kode generated |
| Aset tak terpakai | **Tidak ada tool resmi** | Daftar `flutter: assets:` di `pubspec.yaml` → untuk tiap file: `grep -rn "<nama_file>" lib/ test/` (Grep tool). Aset dirujuk lewat konstanta → cek konstanta | Aset dinamis (`'assets/img/$name.png'`) → hati-hati |
| Urutan import | `directives_ordering` lint + `dart fix`; atau `import_sorter` 🟡 | `dart fix --apply` ; `dart run import_sorter:main` | `dart format` tidak mengurutkan import |
| Ukuran per paket/kode | Size analysis | `flutter build apk --analyze-size` lalu buka JSON di DevTools → App Size | Menunjukkan dampak dependency |
| Kode tak tercakup test (bukan dead code, tapi petunjuk) | coverage | `flutter test --coverage` → `coverage/lcov.info` | Cakupan 0% ≠ tak terpakai |

Aturan: hasil tool = **hipotesis**. Konfirmasi dengan Grep seluruh repo (termasuk `test/`, `integration_test/`, `android/`, `ios/`, `pubspec.yaml`).

## 4. Jebakan — JANGAN dihapus

| Jebakan | Alasan | Cara aman |
|---|---|---|
| File `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart` (generated) | Dibuat `build_runner`; tool "unused" menandainya | Biarkan; atau ubah sumber lalu `dart run build_runner build --delete-conflicting-outputs`. Pastikan kebijakan commit generated (commit vs ignore) konsisten |
| Anotasi `@JsonSerializable`/`@freezed` pada class yang "tidak dipakai" | Dipakai oleh kode generated / reflection-like `fromJson` | Cek hasil generate, bukan hanya referensi |
| Route berbasis string (`'/booking/:id'`, `context.go('...')`, deep link) | Referensi lewat string tak terlihat tool | Grep string rute, `app_links`, manifest, AASA |
| Entry point: `main()`, `@pragma('vm:entry-point')` (FCM background handler), isolate callback | Dipanggil oleh native/engine | Jangan hapus/ubah visibilitas (`_private`) fungsi ber-`vm:entry-point` |
| Plugin native di `pubspec.yaml` tanpa `import` | Registrasi native, efek di Gradle/Podfile/manifest (mis. `firebase_core`, `flutter_native_splash`, `flutter_launcher_icons` dev-dep) | Cek `android/`, `ios/` & konfigurasi plugin sebelum hapus; setelah hapus `flutter clean`, build Android+iOS |
| `Info.plist`/`AndroidManifest.xml` izin & intent-filter | Dipakai kamera/push/deep link | Jangan hapus izin yang dipakai plugin; audit izin berlebih terpisah |
| Aset yang dirujuk dinamis / dari server / `AssetManifest` / font di `pubspec` | Tool tak melihat | Grep pola path; uji layar |
| `l10n` / `intl` generated (ARB) | Dibuat `flutter gen-l10n` | Hapus key hanya bila tak ada di kode & ARB sinkron |
| Kode test-only (`test_keys.dart`, `K`) | Dipakai `integration_test` | Cek `integration_test/` dan Maestro/Patrol |
| Dependency dev (`build_runner`, `flutter_lints`, `dependency_validator`) | Tidak diimpor di `lib/` | Pisahkan penilaian dev vs runtime |
| Fitur R2 yang sengaja di-stub | Kerangka masa depan | Tanyakan; jangan hapus tanpa konfirmasi |
| `pubspec.lock` | Reproducible build | Jangan hapus; commit untuk app |

## 5. Target refactor dari spec

Sumber: [[Spec-Teknis-v1]] §2, §5, §1 (uang integer, ULID, WIB) + [[Rencana-Kerja-v1]] §2 ("HTTP client token, error envelope, penanganan sesi — dipakai C").

### 5.1 Satu layer API client + error envelope
Masalah umum: tiap fitur membuat `Dio`/`http` sendiri, parsing error berulang, token tersebar.
Target: **satu** `ApiClient` (header, auth, timeout, interceptor logging aman, mapping error) dan **satu** `ApiException`.

```dart
// lib/core/api/api_exception.dart (kontrak, Spec §2)
class ApiException implements Exception {
  ApiException({required this.status, required this.code, required this.message, this.fields = const {}});
  final int status;                          // 401/403/404/409/422/429/5xx
  final String code;                         // mis. BOOKING_INVALID_STATE
  final String message;                      // Indonesia, aman ditampilkan
  final Map<String, List<String>> fields;    // 422

  factory ApiException.fromBody(int status, Object? body) {
    final e = (body is Map ? body['error'] : null) as Map?;
    return ApiException(
      status: status,
      code: (e?['code'] as String?) ?? 'UNKNOWN',
      message: (e?['message'] as String?) ?? 'Terjadi kesalahan. Coba lagi.',
      fields: {
        for (final en in (e?['fields'] as Map? ?? {}).entries)
          en.key as String: List<String>.from(en.value as List),
      },
    );
  }
}
```
Langkah refactor: (1) grep `Dio(`/`http.get`/`Uri.parse` di luar `core/api/` → kandidat; (2) pindahkan ke repository yang memakai `ApiClient`; (3) hapus parsing error ganda; (4) satu tempat menangani 401 (logout) & header (`X-App-Version`, `X-Device-Id`, `Idempotency-Key`); (5) tambah test untuk `fromBody`.

### 5.2 State machine UI untuk `period` (dan entitas lain)
Server = sumber kebenaran state (Spec §5). Klien hanya memetakan **status → tampilan & aksi yang diizinkan** di satu tempat (bukan `if (status == 'paid') ...` tersebar).

```dart
enum PeriodStatus { awaitingPayment, expired, paid, inProgress, awaitingConfirmation, completed, settled, cancelled, disputed, refunded, unknown }

PeriodStatus periodStatusFrom(String s) => switch (s) {
  'awaiting_payment' => PeriodStatus.awaitingPayment,
  'expired' => PeriodStatus.expired,
  'paid' => PeriodStatus.paid,
  'in_progress' => PeriodStatus.inProgress,
  'awaiting_confirmation' => PeriodStatus.awaitingConfirmation,
  'completed' => PeriodStatus.completed,
  'settled' => PeriodStatus.settled,
  'cancelled' => PeriodStatus.cancelled,
  'disputed' => PeriodStatus.disputed,
  'refunded' => PeriodStatus.refunded,
  _ => PeriodStatus.unknown,                 // status baru dari server tidak boleh crash
};

extension PeriodUi on PeriodStatus {
  String get label => switch (this) { /* label Indonesia, satu tempat */ _ => '…' };
  bool get canPay => this == PeriodStatus.awaitingPayment;
  bool get canConfirmComplete => this == PeriodStatus.awaitingConfirmation;
  bool get canDispute => this == PeriodStatus.paid || this == PeriodStatus.inProgress || this == PeriodStatus.awaitingConfirmation;
}
```
Uji: tabel test parametrik tiap status → `canPay/canConfirmComplete/canDispute` (sesuai Spec §5). Daftar status final cocokkan dengan `openapi.yaml`. Pola sama untuk Application, Listing, Interview, Payout.

### 5.3 Formatter rupiah integer satu tempat
```dart
// lib/core/money.dart — SATU-satunya tempat format uang
import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String formatRupiah(int amount) => _idr.format(amount);   // 25000 -> "Rp25.000"
```
Target: (1) grep `double` pada field uang, `toStringAsFixed`, `NumberFormat`, `'Rp'` di luar `money.dart`; (2) semua model uang `int`; (3) input pengguna → `int` lewat parser tunggal (hapus titik/`Rp`), tolak desimal; (4) **klien tidak menghitung fee untuk dikirim ke server** — hanya menampilkan angka server ([[01-PRD-Mobile]] PAY-1). Test: `formatRupiah(25000) == 'Rp25.000'`, `0`, jutaan; hati-hati NBSP pada hasil `NumberFormat` di beberapa versi `intl` 🟡 (test persis string).

### 5.4 Struktur feature-first
```
lib/
  core/            # api/, money.dart, time.dart (WIB), error, theme, test_keys.dart, routing
  features/
    auth/ verification/ profile/ listing/ application/ interview/
    chat/ booking/ payment/ wallet/ rating/ notification/ report/
      data/        # repository, dto, mapper
      domain/      # entity, aturan UI (status->aksi)
      presentation/# screen, widget, state (Riverpod/Bloc — netral)
  main.dart
```
Aturan: fitur tidak mengimpor `presentation` fitur lain; berbagi lewat `core/` atau `domain`. Scope sama dengan scope commit ([[07-Git-Commit-Mobile]]). State management ikut keputusan Spec §12.3 — refactor ini tidak bergantung padanya.

### 5.5 Target lain (dari spec)
| Target | Aksi |
|---|---|
| ID = ULID string | Hapus asumsi `int id`; model `String id` |
| Waktu | satu helper UTC→`Asia/Jakarta`; hapus `DateTime.now()` di UI untuk logika bisnis |
| Token | hanya di `SecureTokenStore`; grep `SharedPreferences` + `token` |
| Log | hapus `print`/`debugPrint` berisi body; `avoid_print` aktif |
| Hardcode URL/env | satu `Env` via `--dart-define` |
| Copy UI | string Indonesia terpusat (l10n/ARB atau konstanta) |

## 6. Bandingkan ukuran build

| Metrik | Cara | Catatan |
|---|---|---|
| Ukuran release | `flutter build apk --release --split-per-abi` atau `--target-platform android-arm64` ; `appbundle` untuk estimasi Play | Catat byte sebelum & sesudah di deskripsi PR |
| Rincian | `flutter build apk --analyze-size` → JSON → DevTools "App Size" (diff 2 file) | Lihat paket pembesar |
| iOS | `flutter build ipa --analyze-size` (macOS) 🟡 | |
| Wajar | Penghapusan aset/paket besar turun ≥ ratusan KB; penghapusan kode kecil tak terasa | Jangan klaim penghematan tanpa angka |

## 7. Skrip baseline (opsional)

```bash
# scripts/check.sh
set -e
flutter pub get
flutter analyze
dart fix --dry-run          # tidak mengubah; cek ada saran baru
flutter test
```

## 8. Checklist PR refactor/dead code

- [ ] Baseline (`analyze`, `test`) hijau sebelum; hijau sesudah
- [ ] Satu tujuan per PR; commit kecil dan terpisah (`refactor`, `chore`, `style`)
- [ ] Tidak ada perubahan perilaku (atau dijelaskan eksplisit)
- [ ] Tidak menghapus generated code, entry point (`vm:entry-point`), plugin native, route string, aset dinamis
- [ ] Semua kandidat hapus diverifikasi Grep (lib, test, integration_test, android, ios, pubspec)
- [ ] Build Android + iOS jalan (atau CI) bila menyentuh `pubspec.yaml`/native
- [ ] Ukuran build sebelum/sesudah dicantumkan
- [ ] Tes ditambah untuk logika yang dipindahkan (envelope, status→aksi, rupiah)
- [ ] Tidak ada token/PII di log/komentar/fixture
- [ ] `openapi.yaml` tidak berubah (atau diselaraskan dengan Dev A)

Terkait: [[04-Debug-Playbook-Mobile]] · [[05-E2E-Test-Mobile]] · [[07-Git-Commit-Mobile]] · [[08-Skill-Mobile]]
