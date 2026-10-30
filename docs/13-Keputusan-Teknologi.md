---
tags: [proyek, teknologi, keputusan, laravel, flutter]
status: disetujui
tanggal: 2026-10-29
versi: 1.0
---

# 13 — Keputusan Teknologi: Aplikasi Penghubung Kerja

Tanggal: 29 Oktober 2026
Status: Disetujui
Acuan: PRD versi 1.0 dan file aturan final. Lihat juga [PRD Web v1.3](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) (sumber aturan produk) dan [[09-Arsitektur-App]] (sisi Flutter).

## 1. Keputusan

| Lapisan | Teknologi |
|---|---|
| Backend | Laravel (versi terbaru) |
| Web majikan | Vue 3 dengan Inertia |
| Admin | Filament di atas Laravel |
| Mobile pekerja dan majikan | Flutter (satu aplikasi dengan dua peran) |
| Database | PostgreSQL |
| Cache dan antrean | Redis |
| Penjadwalan | Laravel Scheduler |
| Chat realtime | Laravel Reverb (tahap awal boleh polling) |
| Push notification | Firebase Cloud Messaging |
| Notifikasi WhatsApp | Penyedia WhatsApp Business API di Indonesia |
| Penyimpanan file | Object storage kompatibel S3 dengan bucket privat, akses lewat tautan sementara |
| Pembayaran | QRIS dinamis langsung dari BCA, tanpa agregator (diubah 30 Oktober 2026; PRD K-106, K-107) |
| Verifikasi KTP dan wajah | Penyedia OCR dan liveness pihak ketiga yang terdaftar di Indonesia |
| Peta dan lokasi | Google Maps Platform |
| Hosting | Cloud di region Jakarta, atau VPS dengan Docker |
| Monitoring | Sentry dan log terpusat |
| CI/CD | GitHub Actions |

### 1.1 Versi target (dicek 30 Oktober 2026)

Sama dengan Docs/10 §1.1 di repo backend. Pakai rilis **stabil** terbaru, bukan rilis kandidat, dan konfirmasi ulang nomor patch saat instalasi.

| Komponen | Versi target | Catatan |
|---|---|---|
| Flutter / Dart | **3.47.x / 3.13.x** | CI sudah memakai 3.47.7 dan `sdk: ^3.13.2`. Flutter 3.50 dijadwalkan November 2026; naik lewat PR setelah rilis stabil |
| Paket utama | `flutter_riverpod` 3.x, `go_router` 18.x, `dio` 5.x, `flutter_secure_storage` 11.x, `intl` 0.20.x | Sesuai `pubspec.yaml` saat ini; perbarui minor rutin lewat `flutter pub outdated` |
| Backend untuk test kontrak | PHP **8.5**, Laravel **13.x**, PostgreSQL **18** | Job CI `contract` harus memakai versi ini (Docs/15 §4.3 di repo backend) |

Aturan pembaruan sama dengan backend: rilis kandidat tidak dipakai, versi mayor dinaikkan setelah stabil dan didukung dependensi utama.

## 2. Alasan

- Aturan bisnis yang kompleks (irisan, lock, kredit, gerbang job ketiga, batas booking) lebih aman ditangani di satu backend.
- Visibilitas data bertahap (sebelum dan sesudah lock) dikontrol dari server, bukan dari aturan database.
- Data KTP, foto, video, dan lokasi dapat disimpan di Indonesia.
- Tim sudah menguasai Laravel dan Vue/Inertia, sehingga waktu belajar lebih sedikit.
- Filament menyediakan dashboard admin tanpa membangun dari nol.

## 3. Prinsip Teknis

- **Satu backend, satu database.** Tidak ada microservices pada tahap awal.
- **Logika bisnis di satu tempat.** Aturan harga, booking, lock, pembatalan, dan kredit ditulis sebagai layanan Laravel dengan unit test.
- **Data privat tidak pernah dikirim ke klien sebelum lock.** Filter visibilitas dilakukan di server.
- **Jarak dihitung di server.** Klien hanya menerima kategori jarak.
- **Akses file privat lewat tautan sementara.** Setiap akses dicatat.
- **Penyamaran kontak di chat dilakukan di server** sebelum pesan disimpan.
- **Setiap perubahan status dan pembayaran dicatat** di tabel audit.
- **Enkripsi data sensitif saat disimpan** untuk KTP dan data verifikasi.

## 4. Yang Tidak Dipakai di Tahap Awal

- Microservices
- Machine learning untuk pencocokan
- Dua aplikasi mobile terpisah
- Blockchain atau teknologi sejenis

## 5. Langkah Berikutnya

1. Siapkan repositori, lingkungan pengembangan, dan CI/CD.
2. Pilih penyedia verifikasi KTP, gateway pembayaran, dan penyedia WhatsApp API.
3. Susun skema database dari PRD, termasuk tabel booking, lock, rentang, kredit, dan audit.
4. Mulai dari modul registrasi dan verifikasi, lalu modul rentang dan irisan, lalu booking dan lock.
5. Tulis kasus uji dari bagian 21 PRD sebagai unit test sebelum implementasi.

## 6. Hal yang Perlu Diverifikasi

- Ketersediaan penyedia verifikasi KTP yang sesuai kebutuhan dan biayanya.
- Syarat penyedia WhatsApp Business API di Indonesia.
- Konsultasi hukum untuk lokasi penyimpanan data dan kewajiban PSE.
