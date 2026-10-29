---
tags: [proyek, mobile, keamanan, audit]
status: draft
tanggal: 2026-10-10
versi: 1.0
---

# 11 - Audit Keamanan Mobile (static review, branch feat/core-app-mvp)
> **Kode lama (29 Oktober 2026):** dokumen ini menggambarkan kode yang masih ada. Domain app akan dibangun ulang mengikuti [PRD Web v1.2](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) dan [Skema Database](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/12-Skema-Database.md) di repo pramu-laravel-web (keputusan K-47). Kontrak API berubah total dan ID berganti dari ULID ke UUIDv7.

> **Perubahan lingkup 2026-10-28:** penampungan dana (escrow) dihapus: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, potongan platform 10%, dan sengketa dana **tidak berlaku lagi** (layar M-74..76, M-80..83). Kesepakatan, kontrak (tanpa uang), biaya tayang lowongan, dan rating tetap. Acuan terbaru: [[01-PRD-Mobile]] dan [[09-Arsitektur-App]].

> Acuan: [[03-Celah-Keamanan-Mobile]] (MOB-SEC-01..29, checklist §3, gerbang §4), [[09-Arsitektur-App]], [[01-PRD-Mobile]] §6-§7.
> Metode: baca kode + grep (rg/gitleaks tidak terpasang; grep dipakai, gitleaks tidak dijalankan). Tidak ada build, flutter analyze, ataupun uji dinamis. Item "perlu runtime" dipisah di §5.

## 1. Verdict (gerbang §4)

**NO-GO untuk rilis store.** Fondasi kode kuat (token, logging, URL allowlist, foto sensitif, backup, FLAG_SECURE), tetapi gerbang §4 poin 1, 2, 4, 6 dan 8 belum terpenuhi.

| Gerbang §4 | Status | Alasan singkat |
|---|---|---|
| 1. MOB-SEC-01..07 tertutup | GAGAL | 04 terbuka; 07, 02, 05 sebagian |
| 2. obfuscation + split-debug-info; allowBackup/cleartext; exported | GAGAL sebagian | allowBackup/cleartext/exported OK; obfuscation belum ada skrip/CI |
| 3. token di secure storage; bayar dari deep link | LOLOS | secure_token_store.dart; payment_routes.dart:32-37 |
| 4. pinning teruji, tak ada override | GAGAL | pinValidator tidak pernah diisi; pinning mati default |
| 5. KTP/EXIF | LOLOS (KTP/selfie/SKCK) | foto bukti laporan sebagian (F-05) |
| 6. rahasia di binary / keystore | GAGAL sebagian | tak ada rahasia server; release signing = debug key; mock aktif default (F-01) |
| 7. Data Safety / Privacy Labels | BELUM DINILAI | di luar kode |
| 8. checklist dinamis Android + iOS | BELUM | belum dijalankan |

## 2. Temuan (urut severity)

### High

**F-01 | High | Build rilis memakai mock backend secara default** (tambahan; terkait MOB-SEC-21/07)
- `lib/core/env.dart:3` `bool.fromEnvironment("USE_MOCK", defaultValue: true)`; semua `*_providers.dart` memilih mock bila `Env.useMock`. Tidak ada guard `kReleaseMode`.
- Skenario: `flutter build appbundle --release` tanpa `--dart-define=USE_MOCK=false` menghasilkan app yang tidak pernah memanggil API: login lokal, OTP `123456` (`mock_backend.dart:22`), password mock (`mock_backend.dart:21`), pembayaran/payout "berhasil" palsu.
- Perbaikan: `static const useMock = bool.fromEnvironment("USE_MOCK") && !bool.fromEnvironment("dart.vm.product");` atau `defaultValue: false` dan test memakai `--dart-define=USE_MOCK=true` / override provider (cek `test/helpers`). Tambah cek CI: `strings libapp.so` tidak memuat konstanta mock.

**F-02 | High | Release ditandatangani key debug + applicationId com.example** (MOB-SEC-07, §4.6)
- `android/app/build.gradle.kts:36` `signingConfig = signingConfigs.getByName("debug")`; `:19` `applicationId = "com.example.pramu_apps"` (TODO template).
- Skenario: APK rilis bertanda tangan kunci debug publik; Play menolak `com.example`; `assetlinks.json` (MOB-SEC-02) tidak bisa dibuat karena SHA-256 sertifikat rilis + package belum final.
- Perbaikan: `signingConfigs { create("release") { dari key.properties / secret CI } }`, `release { signingConfig = signingConfigs.getByName("release") }`; ganti applicationId + namespace + paket Kotlin. `key.properties`/`*.jks` sudah di `android/.gitignore:12-14`; `git ls-files` tidak memuat keystore/google-services.

**MOB-SEC-04 | High | TERBUKA: pinning belum berfungsi**
- `lib/core/env.dart:14` `PINNED_SPKI` kosong = pinning mati (default). `lib/core/api/api_client.dart:21` `PinValidator? pinValidator;` tidak pernah diisi (grep hanya api_client.dart). `api_client.dart:49-51`: bila `PINNED_SPKI` diisi, `pinValidator?.call(...) ?? false` menolak SEMUA koneksi (app brick).
- Positif: tidak ada `badCertificateCallback`, tidak ada `http://`/`ws://` di lib; `usesCleartextTraffic="false"` (AndroidManifest.xml:9); tak ada ATS exception.
- Perbaikan: implement hash SPKI (SHA-256) vs `Env.pinnedSpki.split(",")` (min. 2 pin), isi `pinValidator` di `main.dart` sebelum `runApp`; uji MITM di staging; rencana rotasi + force-update (MOB-SEC-26).

**F-03 | High (fungsional, memblok rilis) | Permission INTERNET hanya di manifest debug/profile**
- `android/app/src/main/AndroidManifest.xml` tanpa permission INTERNET (uses-permission); hanya `src/debug` dan `src/profile`. Build rilis tak bisa ke jaringan. Konfirmasi: `apkanalyzer manifest permissions`.
- Perbaikan: tambahkan uses-permission `android.permission.INTERNET` di manifest main. Tak ada permission lain diperlukan saat ini.

### Medium

**MOB-SEC-08 | Medium | TERBUKA: obfuscation/minify belum diatur**
- Tidak ada CI (`.github` tidak ada) atau skrip build; `build.gradle.kts` `release {}` hanya signing.
- Perbaikan: skrip/CI `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=... --dart-define=PINNED_SPKI=...`; simpan symbols privat (`.gitignore` sudah memuat `app.*.symbols`).

**F-04 | Medium | MOB-SEC-02 sebagian: iOS Universal Links belum ada, host Android placeholder**
- Android: `AndroidManifest.xml:36-42` autoVerify + https + host `app.pramu.example` + `pathPrefix="/pay/return"` (placeholder). Router `payment_routes.dart:32-37`: hanya `period` ULID menuju `/periods/:id/status`; layar status memanggil API. Tak ada custom scheme. Sisi ini baik.
- iOS: tidak ada `Runner.entitlements`, tak ada `applinks:`; Info.plist tanpa `CFBundleURLTypes` (bagus). Return pembayaran iOS tak membuka app.
- Perbaikan: ganti host + `assetlinks.json` + `apple-app-site-association` + entitlement `applinks:` untuk domain produksi. Ubah `pathPrefix` menjadi `android:path="/pay/return"` (agar `/pay/returnXYZ` tak ikut).

**F-05 | Medium | TERTUTUP | Foto bukti laporan: file sementara tak disapu, salinan picker tak dihapus** (MOB-SEC-05)
- Ditutup: `evidence_picker.dart` menulis ke `sensitiveDir()` dan selalu menghapus salinan picker (`finally`).
- `lib/features/report/presentation/widgets/evidence_picker.dart:22-26` hasil kompres ke `Directory.systemTemp/bukti_UUID.jpg`, bukan `sensitiveDir()`, sehingga `sweepSensitiveFiles()` (`main.dart:18`, `account_screen.dart:72`) tak menyentuhnya; bila app dimatikan paksa sebelum `deleteTemp` (report_form_screen.dart:57/96/213, report_status_screen.dart:74) foto tertinggal. Baris 31-34: untuk sumber galeri `x.path` tidak dihapus; image_picker menyalin berkas galeri ke cache app sehingga komentar "berkas galeri milik pengguna" kemungkinan keliru (verifikasi di perangkat). Bila kompres gagal (`r == null`), `x.path` juga tak dibersihkan.
- Perbaikan: tulis ke `sensitiveDir()..createSync(recursive: true)` dan `await deleteTemp(x.path)` selalu (salinan picker, bukan berkas asli).
- Catatan: KTP/selfie/SKCK benar: `photo_service.dart:58-92` kompres `keepExif:false`, tulis di `sensitiveDir()`, hapus salinan picker di `finally`, hapus saat batal/ulang/selesai (`verification_state.dart:31-55`, `status_screens.dart:244-274`), `Image.memory`, `requestFullMetadata:false`.

**F-06 | Medium | TERTUTUP | Listing pay tanpa Idempotency-Key** (MOB-SEC-21)
- Ditutup: `ListingRepository.pay(id, {idempotencyKey})`; kunci per niat di `listing_pay_screen.dart`, dirotasi hanya pada penolakan pasti (pola M-74).
- `lib/features/listing/data/api_listing_repository.dart:37-38` `POST /listings/ID/pay` tanpa header, berbeda dengan `api_payment_repository.dart:15-17` dan `api_wallet_repository.dart:47-52`. Double-tap dapat membuat tagihan ganda (dedup server tak terbukti dari klien).
- Perbaikan: tambah `idempotencyKey` pada `ListingRepository.pay` (pola `pay_screen.dart:30,49,56`) dan kirim `ApiClient.idempotent(key)`.

**F-07 | Medium | TERTUTUP | Sesi 401 / revoke-perangkat tidak membersihkan seperti logout manual** (MOB-SEC-20)
- Ditutup: `_clearLocal()` memanggil `sweepSensitiveFiles()`; `PushTokenSync.build` memanggil `deleteToken()` saat sesi menjadi null; `account_screen` memakai try/finally agar logout selalu jalan.
- Logout manual (`account_screen.dart:72-74`) = sweep foto + unregister push + logout. `SessionController.expire()` (`session_controller.dart:135-141`, dari `providers.dart:31`) dan `devices_screen.dart:44` hanya `_clearLocal()` (token + flag). Foto sementara dan token push tak dibersihkan. Laten (NoopPushService), nyata saat FCM dipasang.
- Perbaikan: pindahkan `await sweepSensitiveFiles()` ke `_clearLocal()`; panggil unregister/`deleteToken` pada transisi sesi menjadi null (di `PushTokenSync`). Di `account_screen.dart:73` bungkus unregister `try/finally` agar logout tak gagal bila `deleteToken` melempar non-ApiException.

**MOB-SEC-16 | Medium | TERBUKA: tak ada root detection / Play Integrity / App Attest**
- grep jailbreak/root/integrity/attest kosong; `X-Device-Id` = UUID di prefs (`providers.dart:19-27`). Dapat diterima MVP bila endpoint berisiko dijaga server. Perbaikan: tiket; Play Integrity token ke endpoint OTP/register/payout/rekening, verifikasi server.

**MOB-SEC-14 | Medium | SEBAGIAN (FCM belum ada)**
- Positif: `notificationRoute` (`notification.dart`, bawah kelas AppNotification) = `type` enum + `isUlid`; tipe/ID palsu menghasilkan null lalu snackbar (`notifications_screen.dart:37-42`).
- Belum: channel VISIBILITY_PRIVATE, payload generik, deleteToken saat sesi mati (F-07). Saat `firebase_messaging` dipasang: handler `onMessageOpenedApp`/`getInitialMessage` wajib lewat `notificationRoute` + `isAllowedLocation`; jangan commit `google-services.json` tanpa pembatasan key.

**MOB-SEC-19 | Medium | SEBAGIAN**
- `pubspec.lock` ter-track; dependency langsung sedikit (dio, flutter_secure_storage ^11, image_picker, flutter_image_compress, url_launcher, shared_preferences, go_router, riverpod). `flutter pub outdated` dan manifest merge belum dijalankan.

### Low

- **MOB-SEC-09 sebagian**: FLAG_SECURE via `MainActivity.kt:15-22` + `SecureScreenGuard` (ref-count) di capture KTP/selfie (`capture_step.dart:139`), review (`review_screen.dart:114`), SKCK (`status_screens.dart:284`), bank (`bank_screen.dart:77`), payout (`payout_screen.dart:81`), wallet (`wallet_screen.dart:26`); blur saat tidak resumed. Belum: `UIScreen.isCaptured` (iOS) dan chat (opsional).
- **MOB-SEC-27 terbuka**: tak ada `filterTouchesWhenObscured`. Tambah `window.decorView.filterTouchesWhenObscured = true` di MainActivity (1 baris).
- **MOB-SEC-23 terbuka**: tak ada `local_auth`; payout/ganti rekening tanpa autentikasi ulang. Kontrol server wajib; klien: `local_auth` sebelum submit.
- **MOB-SEC-28 sebagian**: `app_text_field.dart:86-91` OK untuk obscure/sensitive (NIK `review_screen.dart:134`, rekening `bank_screen.dart:141,152`); `otp_input.dart:145-153` belum `enableSuggestions:false`, `autocorrect:false`, `enableIMEPersonalizedLearning:false`.
- **F-08 Low**: `api_client.dart:53-56` menempel Authorization ke semua request. Aman karena path relatif; hardening: hanya bila host request sama dengan host `Env.apiBaseUrl`.
- **F-09 Low (diperiksa, tidak perlu perubahan)**: selfie TIDAK punya jalur galeri (`galleryWhenDenied` default false); hanya KTP, sesuai docs/02 M-12. Semula: KTP/selfie boleh dari galeri bila izin kamera ditolak (`capture_screens.dart:26`, `capture_step.dart:172-180`); melemahkan bukti selfie-KTP. Pertimbangkan hanya kamera untuk selfie.
- **F-10 Low**: folder `web/ linux/ windows/ macos/` ikut repo padahal target Android/iOS; hapus agar permukaan tak bertambah.
- **MOB-SEC-26 sebagian**: `minSdk = 26` (`build.gradle.kts:22`), `X-App-Version` dikirim (`api_client.dart:36`); belum ada penanganan 426 / APP_UPDATE_REQUIRED.
- **MOB-SEC-29 sebagian**: tak ada izin SMS; OTP manual + `AutofillHints.oneTimeCode` (`otp_input.dart:154`); SMS Retriever belum.
- Catatan: SharedPreferences hanya berisi `device_id`, `installed_v1`, `verification_gate_seen`, tema (`providers.dart:19-27`, `secure_token_store.dart:18,46-50`, `session_controller.dart:48`): tanpa PII/token.

## 3. Status per MOB-SEC

| ID | Sev | Status | Bukti utama |
|---|---|---|---|
| 01 | High | Tertutup | `secure_token_store.dart:14-36` (flutter_secure_storage, first_unlock_this_device); `wipeIfFreshInstall` :46-50 dipanggil `main.dart:20`; token tak di URL/log |
| 02 | High | Sebagian | Android autoVerify + status dari API; host placeholder, iOS belum (F-04) |
| 03 | High | Tertutup | tanpa `webview_flutter`; invoice `LaunchMode.inAppBrowserView` + allowlist host (`url_launch.dart:33-35`, `validators.dart:43`) |
| 04 | High | Terbuka | `api_client.dart:21,49-51` |
| 05 | High | Tertutup | KTP/selfie/SKCK dan foto bukti (F-05) di `sensitiveDir()` |
| 06 | High | Tertutup (sumber) | Manifest:5-8 + `res/xml/backup_rules.xml`, `data_extraction_rules.xml`; manifest merge perlu runtime |
| 07 | High | Sebagian | tak ada secret/keystore ter-track; F-02, F-01 |
| 08 | Med | Terbuka | tak ada flag/CI |
| 09 | Med | Sebagian | lihat Low |
| 10 | Med | Sebagian | hanya MainActivity exported (Manifest:12), singleTop, taskAffinity kosong; merge plugin belum diverifikasi |
| 11 | Med | Tertutup | Info.plist: tanpa ATS exception/URLTypes/QueriesSchemes; usage description spesifik; entitlement belum (F-04) |
| 12 | Med | Tertutup | `secure_token_store.dart:20-23`; hapus saat logout/401/install baru |
| 13 | Med | Tertutup | tak ada print/LogInterceptor; debugPrint hanya kDebugMode, method+path+status (`api_client.dart:68-85`); lint avoid_print aktif |
| 14 | Med | Sebagian | lihat di atas |
| 15 | Med | N/A | tak ada DB lokal |
| 16 | Med | Terbuka | - |
| 17 | Med | N/A | tak ada WebSocket (polling, `api_chat_repository.dart:40`); tinjau saat Reverb |
| 18 | Med | Tertutup | semua launchUrl via `url_launch.dart`; `isAllowedUrl` (`validators.dart:46-56`); pengecualian app-settings literal (`capture_step.dart:16`); chat teks polos |
| 19 | Med | Sebagian | - |
| 20 | Med | Tertutup | F-07 (sweep + deleteToken pada semua jalur sesi berakhir) |
| 21 | Med | Tertutup (klien) | fee/total dari server (`payment_repository.dart:14`, `booking.dart:225`); status bayar dari GET; idempotensi F-06 tertutup |
| 22 | Low | Tertutup | grep Clipboard kosong |
| 23 | Low | Terbuka | - |
| 24 | Low | Tertutup (sumber) | manifest main tanpa permission; iOS hanya kamera+foto |
| 25 | Low | N/A | tak ada analytics/crashlytics |
| 26 | Low | Sebagian | - |
| 27 | Low | Terbuka | - |
| 28 | Low | Sebagian | - |
| 29 | Low | Sebagian | - |

## 4. Pemeriksaan §3 yang dijalankan

- SharedPreferences / flutter_secure_storage; print / debugPrint / LogInterceptor (hanya 2 debugPrint di blok kDebugMode); badCertificateCallback, http://, ws:// (0 hasil di lib); webview_flutter (tak ada); launchUrl (terpusat); image_picker (photo_service, evidence_picker); allowBackup, usesCleartextTraffic, exported, autoVerify, debuggable; Info.plist; grep manual secret (hanya konstanta mock dan nama host xendit). gitleaks tidak terpasang (tidak dijalankan). `git ls-files`: tak ada keystore, key.properties, .p12, google-services.json.
- Deep link/router: `allowedPatterns` dari pohon rute; `isAllowedLocation` menolak path tak dikenal, ID non-ULID, dan query listing/booking/period/draft non-ULID (`app_router.dart`); `appRedirect` memaksa guard role.

## 5. Perlu dicek di runtime

1. `apkanalyzer manifest print` dan `permissions` pada build rilis: komponen exported plugin, INTERNET (F-03).
2. R8/minify aktif? `jadx` + `strings libapp.so`: tak ada konstanta mock (F-01), nama kelas terobfuscate.
3. Perilaku `IOHttpClientAdapter.validateCertificate` pada dio ^5.11 saat pinning diimplementasi; uji MITM staging.
4. Salinan cache image_picker untuk sumber galeri (F-05) dan lokasi `Directory.systemTemp` di perangkat.
5. Checklist dinamis §3 pada Android dan iOS fisik.
6. `flutter analyze`, `flutter pub outdated`, `gitleaks detect` (tidak dijalankan).

## 6. Urutan perbaikan

1. F-01, F-02, F-03: satu PR kecil, blocker rilis.
2. MOB-SEC-04 (pinning + uji staging), MOB-SEC-08 (skrip build rilis).
3. F-04, F-05, F-06, F-07.
4. Medium/Low sisanya: tiket + pemilik + tenggat 30 hari atau kurang (§4 GO bersyarat).
