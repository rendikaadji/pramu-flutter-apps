---
tags: [proyek, mobile, flutter, debug, playbook]
status: draft
tanggal: 2026-10-09
versi: 1.0
---

# 04 — Debug Playbook Mobile (Flutter)

> **Perubahan lingkup 2026-10-28:** penampungan dana (escrow) dihapus: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, potongan platform 10%, dan sengketa dana **tidak berlaku lagi** (layar M-74..76, M-80..83). Kesepakatan, kontrak (tanpa uang), biaya tayang lowongan, dan rating tetap. Acuan terbaru: [[01-PRD-Mobile]] dan [[09-Arsitektur-App]].

> Playbook generik berbasis spec ([[Spec-Teknis-v1]] §2 envelope, §8 integrasi) — **belum ada kode**; nama kelas/file di contoh adalah placeholder. Konteks produk: [[PRD-v1]], [[01-PRD-Mobile]]. 🟡 = verifikasi di proyek nyata.

## 1. Triage 5 menit

1. **Reproduksi**: perangkat, OS, versi app (`X-App-Version`), akun/role, env (staging/prod), langkah.
2. **Klasifikasi**: UI/render · state · jaringan · platform (izin/native) · build · uang/privasi.
3. **Uang atau privasi?** → prioritas tertinggi, hotfix langsung (Rencana-Kerja §6). Jangan "dicoba-coba" di production.
4. **Lokalisasi lapisan**: tampilkan request/response (tanpa token/PII, §4) → server salah atau klien salah? Cek `error.code` envelope.
5. **Bandingkan**: debug vs release, emulator vs fisik, Android vs iOS, staging vs prod.
6. Tulis bug report (§12) sebelum fix; tambahkan test regresi.

## 2. Perintah dasar

| Tujuan | Perintah |
|---|---|
| Cek toolchain | `flutter doctor -v` |
| Run verbose (log build+handshake) | `flutter run -v` (pilih device: `flutter devices`, `-d <id>`) |
| Log app Flutter | `flutter logs` |
| Log Android (filter app) | `adb logcat --pid=$(adb shell pidof -s <applicationId>)` (bash) · Windows PowerShell: `adb logcat` lalu filter `Select-String flutter` |
| Log Android error saja | `adb logcat *:E` |
| Crash native Android | `adb logcat -b crash` |
| Perangkat terhubung | `adb devices` |
| Bersihkan | `flutter clean && flutter pub get` |
| Analisis statis | `flutter analyze` |
| Profil performa | `flutter run --profile` (jangan ukur di debug) |
| Ukuran build | `flutter build apk --analyze-size` |
| iOS log | Xcode → Window → Devices and Simulators → Open Console, atau `xcrun simctl spawn booted log stream --predicate 'process == "Runner"'` (simulator, macOS) |
| Buka DevTools | `dart devtools` atau dari IDE saat `flutter run` |

## 3. DevTools — kapan pakai apa

| Tab | Pakai untuk |
|---|---|
| Inspector | Overflow (garis kuning-hitam), constraint salah, widget tree, "Select widget mode", cek `Semantics` |
| Network | Request/response HTTP (dart:io, termasuk Dio) — status, durasi, header. **Hati-hati: tampilan DevTools memuat header/token; jangan screenshot ke publik** |
| Performance | Frame timeline, jank (frame > 16 ms), shader jank, rebuild berlebih (aktifkan "Track widget builds") |
| CPU Profiler | Fungsi lambat (JSON parse besar, kompres gambar di main isolate) |
| Memory | Leak (listener/StreamController tak di-dispose), spike dari gambar besar; ambil snapshot sebelum/sesudah buka-tutup layar |
| Logging | Log `dart:developer` + exception |
| Debugger | Breakpoint, "Pause on exceptions" |

## 4. HTTP logging aman (Dio) — tanpa token/PII

Aturan: **jangan** log header `Authorization`, body login/OTP/password, nomor rekening, KTP/NIK, isi chat, `meeting_url`, `invoice_url`. Log hanya method, path (ULID boleh), status, durasi, `error.code`. Hanya di debug build.

```dart
// Contoh (package dio ^5). Letakkan di satu API client (lihat 06-Refactor).
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SafeLogInterceptor extends Interceptor {
  static const _redactedPaths = {'/auth/login', '/auth/otp/verify', '/me/bank-account', '/verification'};

  bool _skipBody(RequestOptions o) => _redactedPaths.any(o.path.contains);

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    o.extra['t0'] = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('--> ${o.method} ${o.path}');   // tanpa header, tanpa body
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    if (kDebugMode) {
      final ms = DateTime.now().millisecondsSinceEpoch - (r.requestOptions.extra['t0'] as int? ?? 0);
      debugPrint('<-- ${r.statusCode} ${r.requestOptions.path} ${ms}ms');
    }
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    if (kDebugMode) {
      final err = e.response?.data is Map ? (e.response!.data as Map)['error'] : null;
      final code = err is Map ? err['code'] : null; // envelope Spec §2
      debugPrint('<-- ERR ${e.response?.statusCode} ${e.requestOptions.path} code=$code type=${e.type.name}');
    }
    h.next(e);
  }
}
```

Jangan pakai `LogInterceptor(requestHeader: true, requestBody: true, responseBody: true)` bawaan di build yang dibagikan. Crash reporter: set user id = ULID, bukan HP/email; matikan breadcrumb jaringan yang membawa body 🟡.

## 5. Tabel gejala → penyebab → cek

### 5.1 Jaringan & API
| Gejala | Penyebab umum | Cek / perintah |
|---|---|---|
| Semua request gagal di emulator Android | `localhost` menunjuk emulator itu sendiri | Pakai `10.0.2.2` ke host; atau URL staging. iOS simulator memakai `localhost` |
| `SocketException`/`HandshakeException` | Sertifikat/tanggal perangkat salah, HTTP cleartext diblok | Cek jam perangkat; Android `usesCleartextTraffic` hanya untuk dev; iOS ATS blok `http://` |
| `DioException connectionTimeout` | Server lambat/jaringan, timeout terlalu kecil | `curl -w "%{time_total}" <url>`; cek `connectTimeout`/`receiveTimeout` |
| 401 mendadak | Token dicabut (logout di perangkat lain), token kosong karena secure storage gagal baca | Cek keberadaan token (jangan cetak nilainya, cukup `isNotEmpty`); lihat §6 |
| 403 | Role salah / belum `verified` / bukan pemilik | Cek `error.code` + `active_role` yang dikirim |
| 404 pada ID | ID bukan ULID (pakai bigint) atau resource bukan milik user (Policy bisa menjawab 404) | Pastikan model memakai `ulid` string |
| 409 `*_INVALID_STATE` | UI memakai state basi | Muat ulang entitas; jangan retry buta |
| 422 | Validasi | Petakan `error.fields` ke form |
| 429 | Rate limit (OTP 5/jam, umum 60/mnt) | Hormati `Retry-After` jika ada 🟡; debounce tombol |
| JSON parse error / `type 'Null' is not a subtype` | Model tak cocok `openapi.yaml`; field nullable | Bandingkan dengan OpenAPI; model generated lalu `dart run build_runner build -d` |
| Uang salah tampil | Perhitungan di klien / float | Semua `int` rupiah, format di satu helper (06-Refactor). Jangan `double` |
| Waktu salah (selisih 7 jam) | UTC belum dikonversi ke WIB | Parse `DateTime.parse(..).toUtc()` lalu tampil di `Asia/Jakarta` |
| Multipart gagal | Ukuran > 5 MB, MIME salah | Kompres; periksa `error.fields.file` |

### 5.2 Auth, 401 & token
Spec hanya mendefinisikan **Bearer Sanctum per perangkat** — tidak ada endpoint refresh (🟡 konfirmasi).
- Interceptor `onError`: jika 401 pada endpoint non-auth → hapus token, reset state, navigasi ke login, simpan rute tujuan. **Cegah loop**: jangan retry otomatis; dan serialisasikan sehingga banyak 401 paralel hanya memicu satu logout.
- Jika kelak ada refresh: gunakan satu `Future` bersama (single-flight) agar request paralel menunggu refresh yang sama; refresh gagal → logout.
- Token hilang setelah update/restore: Android Keystore + backup (`allowBackup`) bisa merusak data secure storage; iOS Keychain bertahan setelah uninstall → pertimbangkan hapus saat first-run 🟡.
- Logout: panggil `/auth/logout`, hapus token & cache walau request gagal; hapus FCM token di server (`/me/devices`) 🟡.

### 5.3 WebSocket (Reverb)
| Gejala | Penyebab | Cek |
|---|---|---|
| Tidak konek | Host/port/scheme (`ws`/`wss`) salah, app key salah, firewall | `curl -i` ke host; cek config `REVERB_*` di staging |
| Konek tapi channel privat ditolak | Endpoint auth broadcasting 403/401 (Bearer tak dikirim) | Lihat log auth channel; pastikan header `Authorization` ikut; channel `private-conversation.{ulid}` hanya 2 peserta |
| Pesan tidak masuk realtime tapi ada di REST | Event tidak di-broadcast / klien belum subscribe | Subscribe setelah koneksi `established`; pastikan queue worker jalan (server) |
| Putus saat background | OS menutup socket | Reconnect saat `AppLifecycleState.resumed` + sinkron pesan > id terakhir lewat REST |
| Pesan ganda | Optimistic bubble + event dari server | Dedup by `ulid` pesan |
| Putus-sambung terus | Tidak ada heartbeat/ping handling | Pakai ping paket klien; backoff eksponensial |
Selalu ingat: REST adalah sumber kebenaran, WS hanya akselerasi (Spec §8).

### 5.4 FCM / push tidak masuk
Urutan cek (berhenti saat ketemu):
1. Izin: iOS `requestPermission()` = authorized? Android 13+ `POST_NOTIFICATIONS` granted?
2. Token ada & terkirim ke `/me/devices` (cek server punya token terbaru; `onTokenRefresh` ditangani).
3. Firebase project benar: `google-services.json` / `GoogleService-Info.plist` cocok dengan `applicationId`/bundle id & env (staging ≠ prod).
4. **iOS**: APNs Authentication Key (.p8) + Key ID + Team ID sudah diunggah di Firebase Console → Cloud Messaging; capability *Push Notifications* & *Background Modes → Remote notifications*; **tes di perangkat fisik** (simulator terbatas); sandbox vs production APNs sesuai build (TestFlight/App Store = production).
5. Payload: pesan `notification` (ditampilkan OS saat background) vs `data`-only (butuh handler & iOS `content-available`). Payload kita minimal `type`+`id`.
6. Handler: `FirebaseMessaging.onBackgroundMessage` harus fungsi **top-level** dengan `@pragma('vm:entry-point')`; `onMessage` (foreground — OS tidak menampilkan banner sendiri di Android; perlu notifikasi lokal 🟡 `flutter_local_notifications`); `onMessageOpenedApp` & `getInitialMessage()` (terminated).
7. Android: channel notifikasi (importance), mode hemat baterai vendor (Xiaomi/Oppo), app di-force stop (tidak menerima).
8. Server: kirim lewat queue → pastikan queue worker hidup; cek respons FCM `UNREGISTERED` → hapus token.
9. Tes terpisah: Firebase Console → Cloud Messaging → "Send test message" dengan token perangkat. Jika ini masuk, masalah di server/payload; jika tidak, di klien/konfigurasi.

### 5.5 Deep link tidak terbuka
| Gejala | Penyebab | Cek |
|---|---|---|
| Android: `asisten://...` tak membuka app | `intent-filter` tidak ada/`android:exported` salah/ `launchMode` | `adb shell am start -W -a android.intent.action.VIEW -d "asisten://pay/return?period=XYZ" <applicationId>` |
| Android App Links (https) buka browser | `assetlinks.json` tak valid / SHA-256 keystore salah (upload key vs Play signing key) | Cek `adb shell pm get-app-links <applicationId>` 🟡; verifikasi file di `/.well-known/assetlinks.json` |
| iOS custom scheme gagal | URL Types belum di `Info.plist` | `xcrun simctl openurl booted "asisten://..."` |
| iOS Universal Link buka Safari | AASA salah/Associated Domains belum, uji dari Notes/Messages (bukan ketik di Safari) | Cek `applinks:` di Entitlements |
| Link terbuka tapi tak ke layar benar | Cold start: link datang sebelum router siap | Tangani initial link setelah auth+router siap; antre |
| Return Xendit tak memicu app | WebView mengabaikan custom scheme | Intercept navigasi WebView (lihat §5.6) |

### 5.6 WebView Xendit
| Gejala | Cek |
|---|---|
| Halaman putih | Android: `INTERNET` permission; JS diaktifkan (`JavaScriptMode.unrestricted` bila hosted page butuh); cek log `onWebResourceError` |
| Tak kembali ke app setelah bayar | Tangkap `NavigationDelegate.onNavigationRequest` untuk `success_url`/`failure_url` → `NavigationDecision.prevent` + tutup + cek status server |
| E-wallet/Bank app tak terbuka (OVO/DANA/deeplink) | Skema non-http(s) tak ditangani WebView → luncurkan `url_launcher`; Android 11+ butuh `<queries>` di manifest; iOS `LSApplicationQueriesSchemes` 🟡 |
| Status UI "gagal" padahal uang masuk | Jangan percaya redirect; poll `GET /bookings/{id}` sampai webhook memproses (Spec §8 / PAY-2) |
| Bayar ganda | Tombol Bayar tanpa guard; `Idempotency-Key` baru tiap tap → pakai satu key per niat; disable tombol saat proses |
| Kedaluwarsa invoice | Minta invoice baru lewat endpoint pay (server menentukan) |
| Debug WebView | Android: `chrome://inspect` (aktifkan debugging WebView di debug build); iOS Safari → Develop |

### 5.7 Build gagal
| Gejala | Penyebab | Perintah |
|---|---|---|
| Gradle: `Could not resolve…` / timeout | Jaringan/proxy, cache rusak | `cd android && ./gradlew clean` (Windows: `gradlew.bat clean`), `./gradlew --stop`, coba `--refresh-dependencies` |
| `Unsupported class file major version` / AGP vs JDK | Versi JDK tak cocok Gradle/AGP | `flutter doctor -v` (lihat JDK yang dipakai), `java -version`; samakan dengan versi yang diminta Flutter terbaru 🟡 |
| `minSdkVersion` conflict | Plugin butuh min lebih tinggi | Naikkan `minSdk` di `android/app/build.gradle(.kts)` sesuai keputusan PRD |
| Multidex / 64K | Banyak plugin | Aktifkan multidex (min SDK ≥ 21 otomatis) |
| `google-services.json` tidak ditemukan | File tidak di-commit (sengaja) | Letakkan di `android/app/` per env; lihat [[07-Git-Commit-Mobile]] |
| CocoaPods: `pod install` gagal / versi spec | Repo spec basi, arsitektur M1 | `cd ios && pod repo update && pod install` ; atau `rm -rf Pods Podfile.lock && pod install`; `flutter clean` dulu |
| iOS: `The iOS deployment target is set to X, but range is Y` | `IPHONEOS_DEPLOYMENT_TARGET` < min plugin | Set di Podfile `platform :ios, '14.0'` & Xcode project |
| iOS signing | Team/profile salah | Xcode → Signing & Capabilities; bundle id unik |
| `build_runner` konflik | Generated file basi | `dart run build_runner build --delete-conflicting-outputs` |
| Dependency conflict | Versi paket | `flutter pub deps --style=compact`, `flutter pub outdated`, `dart pub upgrade --major-versions` (hati-hati) |
| Release crash tapi debug normal | R8/ProGuard menghapus kelas, izin release (INTERNET di main manifest) | `flutter build apk --release`; cek `android/app/src/main/AndroidManifest.xml` (bukan hanya debug/profile); aturan proguard plugin |

### 5.8 Jank & performa
| Gejala | Penyebab | Tindakan |
|---|---|---|
| List chat/lowongan patah-patah | `ListView` non-lazy, rebuild seluruh list tiap pesan, gambar besar | `ListView.builder`, `const` widget, `itemExtent`/key stabil, `cacheWidth/cacheHeight` pada `Image.network`, pagination 50 |
| Jank saat parse JSON besar | Main isolate | `compute()`/`Isolate.run` |
| Start lambat | Inisialisasi sinkron di `main()` (Firebase, storage) | Paralel (`Future.wait`), splash, tunda yang tidak kritis |
| Memori naik | Listener/Stream/Controller tidak di-dispose, foto KTP full-res di memori | Dispose; kompres sebelum preview; DevTools Memory diff |
| Shader jank (iOS first run) | Kompilasi shader | Impeller (default iOS modern) 🟡 cek versi Flutter; profil mode |
Selalu ukur di **profile mode perangkat fisik kelas menengah**.

## 6. Crash reporting 🟡 (keputusan terbuka)

| Opsi | Catatan |
|---|---|
| `firebase_crashlytics` | Sudah ada Firebase (FCM); tangani `FlutterError.onError` & `PlatformDispatcher.instance.onError`; unggah dSYM (iOS) & mapping (Android) |
| `sentry_flutter` | Alternatif; self-host mungkin; ada scrubbing PII |
Aturan: user id = ULID; **scrub** body request/header; tidak ada nomor HP/email/KTP/isi chat di breadcrumb (PRD §7 Observabilitas); persetujuan UU PDP. Simbol: simpan artefak `--split-debug-info` + `--obfuscate` bila dipakai (`flutter build apk --obfuscate --split-debug-info=build/symbols`).

## 7. Prioritas bug

| Prioritas | Kriteria | Contoh | SLA usul 🟡 |
|---|---|---|---|
| **P0 uang/privasi** | Salah nominal, bayar ganda, saldo salah, status bayar salah, kebocoran data (KTP/chat/kontak), admin/lawan bisa lihat data privat | Total bayar ≠ server; tombol bayar mengirim 2 invoice; kontak tampil sebelum bayar | Hotfix langsung, stop rilis |
| P1 blocker alur | Tidak bisa login/daftar/upload/bayar/lamar | Crash saat start; OTP tak terbaca | Hari yang sama |
| P2 fungsi rusak sebagian | Filter, push tertentu, chat tertunda | | Sprint berjalan |
| P3 kosmetik | Overflow kecil, typo | | Backlog |

## 8. Templat bug report

```markdown
**Judul**: [P?][Area] ringkas
**Lingkungan**: app v1.0.0+12 · Android 13 / iOS 17.4 · perangkat · staging/prod · role aktif
**Akun uji**: (ID/ULID saja, bukan HP/email/password)
**Langkah**: 1. … 2. … 3. …
**Harapan**:
**Aktual**:
**Frekuensi**: selalu / kadang (x/10)
**Bukti**: screenshot/rekam layar (BURAM-kan PII/KTP), log (tanpa token), `error.code`, request ULID/waktu (UTC)
**Uang/privasi?**: ya/tidak (jika ya: P0)
**Dugaan**: (opsional)
```

## 9. Checklist sebelum menutup bug
- [ ] Penyebab akar tertulis di PR, bukan hanya gejala
- [ ] Test regresi (unit/widget/integration) ditambah ([[05-E2E-Test-Mobile]])
- [ ] Log debug sementara dihapus; tidak ada token/PII baru di log
- [ ] Diuji pada Android + iOS bila menyentuh platform
- [ ] Commit sesuai [[07-Git-Commit-Mobile]]

Terkait: [[01-PRD-Mobile]] · [[Spec-Teknis-v1]]
