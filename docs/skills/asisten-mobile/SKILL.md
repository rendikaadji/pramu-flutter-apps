---
name: asisten-mobile
description: Aturan wajib untuk mengerjakan app Flutter "Asisten Marketplace" (Android+iOS, 1 app 2 role Pencari/Asisten, backend Laravel). Pakai saat menulis, mengubah, mereview, mendebug, mengetes, me-refactor, atau commit kode di repo asisten-mobile - terutama yang menyentuh uang/rupiah, pembayaran Xendit, auth/token, error API, chat Reverb, push FCM, verifikasi KTP, atau pemisahan role. Jangan dipakai untuk repo lain.
---

# asisten-mobile — aturan domain app Flutter Asisten Marketplace

Sumber kebenaran: `Spec-Teknis-v1.md` (kontrak API), `PRD-v1.md` (fitur & ID), `openapi.yaml` di repo API. Jika konflik: OpenAPI > Spec > PRD > skill ini. Detail ada di `references/` (lihat bawah); baca hanya bagian yang relevan.

Belum tentu repo sudah punya kode: **baca kode yang ada dulu**, ikuti konvensi yang sudah terpasang (state management Riverpod/Bloc masih keputusan terbuka — jangan memaksakan salah satu; jangan menambah library tanpa diminta).

## 1. Aturan wajib (jangan dilanggar)

### Uang
- Semua nominal = **`int` rupiah** (tanpa `double`, tanpa desimal). Di model, di JSON, di state.
- Format tampilan lewat **satu fungsi** `formatRupiah(int)` (contoh: `25000` -> `Rp25.000`). Dilarang `NumberFormat`/`'Rp$x'`/`toStringAsFixed` di luar file itu.
- **Klien tidak menghitung fee untuk dikirim ke server.** Fee 10% dipotong penuh dari sisi asisten (Pencari bayar sesuai nominal yang diinput; asisten melihat nominal bersih 90%); tidak ditampilkan sebagai baris biaya ke pengguna. Escrow, settlement dihitung server. Klien hanya menampilkan angka dari server.
- Status bayar (`paid`, dst) hanya dipercaya dari **server (webhook)**. Deep link/redirect WebView hanya memicu refresh status, bukan menandai sukses.
- Endpoint uang (bayar, penarikan) kirim `Idempotency-Key` (UUID per niat; dipakai ulang saat retry; tombol dinonaktifkan saat proses). POST uang jangan auto-retry dengan key baru.

### ID & waktu
- ID publik di API = **ULID (String)**. Jangan asumsikan `int`. Jangan menebak/menyusun ID.
- Waktu dari API = UTC; tampil **WIB (`Asia/Jakarta`)** lewat satu helper. Locale `id_ID`, teks UI bahasa Indonesia.

### API client & error
- **Satu** layer API client (header, auth, timeout, mapping error). Dilarang membuat `Dio`/`http` baru di fitur.
- Header: `Authorization: Bearer`, `Accept-Language: id`, `X-App-Version`, `X-Device-Id`.
- Envelope sukses `{ "data", "meta" }`; **envelope error** `{ "error": { "code", "message", "fields" } }`. Selalu parse ke `ApiException(status, code, message, fields)`.
- Penanganan: 401 -> logout/login ulang (satu kali, tanpa loop); 403 -> arahkan verifikasi/pesan; 409 `*_INVALID_STATE` -> muat ulang entitas; 422 -> petakan `fields` ke form; 429 -> tunda/disable tombol.
- State dari server (period, application, listing, payout, verification) dipetakan ke UI di **satu tempat** (status -> label + aksi yang diizinkan); status tak dikenal jangan crash (`unknown`).

### Keamanan & privasi
- Token **hanya** di `flutter_secure_storage` (Keychain/Keystore). Bukan `SharedPreferences`, bukan file, bukan log.
- **Jangan log** token, header `Authorization`, password/OTP, NIK/KTP, nomor rekening, isi chat, `meeting_url`, `invoice_url`, HP/email. `avoid_print` aktif; logging jaringan hanya method/path/status/`error.code` dan hanya di debug.
- Crash reporter/analytics: user id = ULID, tanpa body request, tanpa PII.
- Kontak pribadi (HP/alamat) tidak ditampilkan sebelum booking dibayar; teks chat yang sudah disamarkan server ditampilkan apa adanya.
- Tidak ada UI admin di app; jangan menampilkan ulang dokumen KTP/SKCK lewat URL publik; upload ≤ 5 MB (jpg/png/pdf), kompres dulu.
- Jangan commit: keystore (`*.jks`, `key.properties`), `.env`, `google-services.json`/`GoogleService-Info.plist` (ikuti kebijakan tim), kunci APNs, build output.

### Pemisahan role (Pencari vs Asisten)
- Satu akun, `active_role` menentukan navigasi & layar. Ganti role via `/me/switch-role`; reset stack navigasi.
- Fitur per role: Pencari = lowongan, pelamar, shortlist, jadwal wawancara, catatan wawancara (privat pencari), bayar, konfirmasi selesai. Asisten = cari kerja, lamar, jawab screening, dompet, rekening, tarik dana.
- Jangan tampilkan aksi role lain; **server tetap penentu izin** (403) — UI hanya mempermudah.
- Aksi posting/lamar/transaksi terkunci sampai `verified`.

### Tes (key untuk finder)
- Elemen interaktif kritis (field, tombol, kartu, status) punya `Key` dari satu file `lib/core/test_keys.dart` (mis. `K.loginSubmit`, `K.payButton`, `K.listingCard(ulid)`); tambahkan `Semantics(label/identifier)` untuk Maestro/aksesibilitas. Jangan pakai teks UI sebagai finder utama.
- Logika uang, status->aksi, `ApiException.fromBody`, formatter rupiah: wajib unit test. Alur kritis: `integration_test` (login -> lamar; bayar sandbox dengan webhook disimulasi dari backend staging).
- **Playwright tidak bisa menggerakkan app Flutter native**; hanya untuk Flutter Web (smoke) dan E2E API.

## 2. Platform
- Pembayaran: `invoice_url` Xendit dibuka di WebView (allowlist https), tangkap `success_url`/`failure_url`, tutup, cek status ke API. E-wallet/bank deep link via `url_launcher`.
- Push FCM: payload `type` + `id` (ULID), isi diambil dari API; handler background fungsi top-level `@pragma('vm:entry-point')`; token ke `/me/devices`; iOS wajib APNs key + perangkat fisik untuk uji.
- Realtime chat: Reverb private channel `private-conversation.{ulid}`; REST = sumber kebenaran, WebSocket hanya akselerasi; dedup by ULID; reconnect + sinkron.
- Min OS (usulan, belum final): Android 8+, iOS 14+.

## 3. Perintah standar

| Tujuan | Perintah |
|---|---|
| Dependensi | `flutter pub get` |
| Statis | `flutter analyze` (harus bersih) |
| Auto-fix | `dart fix --dry-run` lalu `dart fix --apply` ; `dart format .` |
| Test | `flutter test` ; integrasi: `flutter test integration_test -d <device>` |
| Generate | `dart run build_runner build --delete-conflicting-outputs` (jika dipakai) |
| Build Android | `flutter build apk --release` / `flutter build appbundle --release` |
| Build iOS | `flutter build ipa --release` (macOS) |
| Ukuran | `flutter build apk --analyze-size` |
| Diagnosa | `flutter doctor -v` ; `flutter logs` ; `adb logcat` |
Sebelum bilang selesai: jalankan `flutter analyze` + `flutter test`, laporkan hasil jujur (perintah tidak ada/tool belum terpasang = katakan, jangan klaim lulus).

## 4. Format commit & branch
- Conventional Commits: `type(scope): subject` (imperatif, ≤ 72 karakter, tanpa titik).
- type: `feat fix refactor perf test docs style build ci chore revert`.
- scope: `auth verification profile listing application interview chat booking payment wallet rating notification report ui build ci` (+ `core`, `deps`).
- Atomic: satu perubahan logis per commit. Branch: `main` <- `develop` <- `feat/<scope>-<singkat>`; PR 1 reviewer, CI test + lint.
- Versi: `pubspec.yaml version: X.Y.Z+N` (N naik tiap upload); tag `vX.Y.Z+N`.
- Hanya commit jika diminta pengguna; akhiri pesan commit dengan atribusi yang diminta lingkungan.

## 5. Prioritas
Bug uang/privasi (salah nominal, bayar ganda, kebocoran PII/kontak/chat) = P0, hentikan rilis, hotfix. Jangan memotong: verifikasi, test uang, privasi, keamanan webhook (sisi server).

## 6. Referensi (baca sesuai kebutuhan)
Folder dokumen: `C:\Users\rendi\OneDrive\Documents\Obsidian Vault\02-Proyek\Asisten-Marketplace\`
- `Spec-Teknis-v1.md` — kontrak API, envelope §2, endpoint §3, state machine §5, ledger §6, integrasi §8, keamanan §9, uji §10.
- `PRD-v1.md` — ID fitur & AC (AUTH VER PRO LST APP INT CHT BKG PAY RAT NTF PRV).
- `Mobile\01-PRD-Mobile.md` — user story & AC sisi klien, platform, offline/error, rilis store.
- `Mobile\04-Debug-Playbook-Mobile.md` — triage, gejala->penyebab, logging aman, FCM/deep link/WebView/Gradle/Pods.
- `Mobile\05-E2E-Test-Mobile.md` — integration_test, Patrol/Maestro, Playwright API, CI, data uji.
- `Mobile\06-Refactor-DeadCode-Mobile.md` — prosedur aman, jebakan, target refactor (API client, status->aksi, rupiah, feature-first).
- `Mobile\07-Git-Commit-Mobile.md` — commit, branch, versi/tag, larangan commit, template PR.
