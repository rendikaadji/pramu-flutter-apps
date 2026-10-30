---
name: pramu-mobile
description: Aturan wajib untuk aplikasi Flutter Pramu (Android dan iOS, satu aplikasi dua peran majikan dan pekerja, backend Laravel /api/v1). Pakai saat menulis, mengubah, mereview, mendebug, atau mengetes kode di repo pramu-flutter-apps, terutama yang menyentuh API, sesi, peran, pembayaran QRIS, kamera dan video, bahasa, atau status. Jangan dipakai untuk repo backend.
---

# Pramu Mobile: aturan wajib

**Sumber kebenaran** ada di repo `pramu-laravel-web` (`main`), kecuali yang ditandai repo ini:

| Butuh | Baca |
|---|---|
| Aturan produk, status, kode kesalahan, kasus uji | `Docs/01-PRD-Web.md` (v1.3) |
| Kontrak endpoint dan bentuk data | `Docs/openapi.yaml` |
| Arsitektur dan urutan kerja | `Docs/15-Arsitektur-dan-Migrasi.md` |
| Layar, wireframe, microcopy, peta status | `Docs/02-UIUX-Brief-Web.md` (v2) |
| Hal khusus aplikasi | `docs/02-UIUX-Brief-Mobile.md` (v2, repo ini) |
| Token dan komponen | `docs/10-Design-System-App.md` (repo ini) |
| Cara menguji | `Docs/18-Rencana-Uji.md` |
| Kontrol keamanan | `Docs/19-Keamanan.md` §9 |
| Versi | `docs/13-Keputusan-Teknologi.md` §1.1 (repo ini) |

Jika konflik, urutannya: `openapi.yaml`, lalu PRD, lalu brief, lalu skill ini. Dokumen bertanda **USANG** (docs/01, 03, 05, 09, 11, 12) menggambarkan model lama (lowongan, wawancara, escrow, Xendit). Jangan ikuti isinya untuk kode baru.

## Aturan wajib

1. **Server memutuskan, klien menampilkan.** Klien tidak menghitung harga, fee, kuota, batas waktu, atau aturan PRD. Tombol yang tampil = `aksi_tersedia` dari API. Teks dialog konfirmasi = `akibat` dari API. Alasan tombol nonaktif = `alasan_nonaktif` (Docs/15 §2.3).
2. **Uang = `int` rupiah.** Tampilkan `Uang.teks` dari server jika ada, atau format lewat satu helper di `core/money` dengan locale aktif.
3. **ID = UUID (String).** Jangan berasumsi `int` atau ULID. Jangan menyusun ID sendiri.
4. **Waktu:** API memakai UTC. Tampilan memakai WIB lewat helper `core/time`. Hitung mundur memakai waktu server (`BatasWaktu.sampai`), bukan jam perangkat.
5. **Satu API client** (`core/api`): mengurus `Authorization`, `Accept-Language`, `Idempotency-Key`, timeout, dan pemetaan galat ke `ApiException(status, code, message, fields)`. Jangan membuat `Dio` baru di fitur.
6. **Idempoten:** setiap aksi yang mengubah status atau uang mengirim `Idempotency-Key` (UUID per niat). Kunci yang sama dipakai ulang saat mencoba lagi. Tombol terkunci selama proses.
7. **Tindakan per kode galat** mengikuti Docs/13 §5.4, misalnya `OUTSTANDING_BILL` → tombol "Bayar tagihan", `INVALID_STATE` → muat ulang data. Kode tidak dikenal tidak boleh membuat aplikasi crash.
8. **Pembayaran hanya QRIS BCA.** QR dirender dari `qr_payload`. Status lunas hanya dipercaya dari server (event Reverb atau `GET /tagihan/{id}`), tidak pernah dari klien. Tidak ada WebView gateway (brief mobile v2 §6).
9. **Dua bahasa:** semua teks lewat `context.l10n` (ARB `id` dan `en`, `gen-l10n`). Tidak ada string literal di `lib/features/**`. Isian pengguna (chat, deskripsi, nama Tulis sendiri) ditampilkan apa adanya.
10. **Peran:** satu akun dengan peran aktif. Navigasi dan warna mengikuti peran (majikan biru, pekerja teal). Server tetap penentu izin.
11. **Privasi:**
    - Token hanya di `flutter_secure_storage`.
    - Tidak ada log berisi token, OTP, NIK, alamat, isi chat, atau `qr_payload`.
    - Layar KTP, swafoto, dan QR memakai `FLAG_SECURE`.
    - Berkas sementara dihapus setelah unggah.
    - Koordinat pihak lain tidak pernah ada di respons API, jadi jangan dicari.
12. **UI hanya lewat `app_ui`:** tidak ada warna, ukuran, atau durasi yang ditulis langsung (Design System §1). Komponen baru dimasukkan ke galeri desain.
13. **Test key:** elemen penting punya `Key` dari `core/test_keys.dart`. Jangan memakai teks UI sebagai pencari di test.

## Test

- Unit test wajib untuk pemetaan JSON, `ApiException`, helper uang dan waktu.
- Widget test untuk layar yang memakai `aksi_tersedia`.
- Golden test 10 layar inti untuk `id`, `en`, `en-XA` (bahasa semu +40%) di skala 100% dan 130%, terang dan gelap (UJ-74).
- Test kontrak live terhadap backend dengan PostgreSQL 18 di job CI `contract`.
- Mock repositori memakai contoh dari `openapi.yaml`.

## Perintah

| Tujuan | Perintah |
|---|---|
| Dependensi | `flutter pub get` |
| Statis | `flutter analyze --fatal-infos` (harus bersih) |
| Format | `dart format .` |
| Terjemahan | `flutter gen-l10n` |
| Test | `flutter test` |
| Golden | `flutter test tool/screenshots/screens_test.dart --update-goldens` |
| Build | `flutter build appbundle --release` / `flutter build ipa --release` |

Sebelum menyatakan selesai, jalankan `flutter analyze` dan `flutter test`, lalu laporkan hasilnya apa adanya.

## Commit dan branch

- **Format:** Conventional Commits, `type(scope): subject`, kalimat perintah, ≤ 72 karakter.
- **Scope:** `akun`, `verifikasi`, `job`, `pencarian`, `booking`, `penugasan`, `tagihan`, `chat`, `reputasi`, `notifikasi`, `beranda`, `ui`, `l10n`, `core`, `deps`, `ci`, `docs`.
- **Branch:** pekerjaan domain baru di `feat/domain-baru`, sama dengan nama branch backend agar job CI `contract` memakai branch yang sama.
- **Jangan commit:** keystore, `key.properties`, `.env`, kunci APNs, atau build output.
