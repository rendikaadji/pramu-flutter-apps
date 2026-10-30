---
tags: [proyek, ui-ux, mobile]
status: draft
tanggal: 2026-10-30
versi: 2.0
---

# 02 — Brief UI/UX Mobile v2 (Flutter, Android + iOS, satu aplikasi dua peran)

Acuan:
- [PRD Web v1.3](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md): aturan produk.
- [Brief UI/UX v2 semua platform](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/02-UIUX-Brief-Web.md): IA, alur, daftar layar, wireframe 10 layar inti, peta status, dan microcopy.
- [Audit PRD dan UI/UX](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/13-Audit-PRD-UIUX.md): pola UI wajib.
- [[10-Design-System-App]]: token dan komponen. Sumber nilai yang berlaku.

> **v2 menggantikan v1 seluruhnya.** v1 merancang lowongan, wawancara, escrow, dan dompet. Isinya masih ada di riwayat git.
>
> Dokumen ini hanya memuat hal yang **khusus aplikasi**. Semua yang sama di web dan aplikasi ada di Brief v2 semua platform. Jika keduanya berbeda, yang berlaku adalah PRD, lalu Brief semua platform, lalu dokumen ini.

## 1. Prinsip khusus aplikasi

1. **Tahan jaringan buruk.** Draf tersimpan di perangkat, unggahan bisa dilanjutkan, dan tidak ada input yang hilang.
2. **Peran selalu terlihat.** Chip peran di app bar, dan warna navigasi aktif mengikuti peran (majikan biru, pekerja teal).
3. **Kamera dipandu.** Setiap pengambilan foto atau video punya bingkai, contoh, dan pemeriksaan sebelum unggah.
4. **Notifikasi membawa ke tempat menjawab.** Ketuk push langsung membuka layar tujuan, bukan Beranda.

## 2. Navigasi

- **Navigasi bawah 5 tab per peran**, sesuai Brief semua platform §4.1. Back stack terpisah per tab.
- **Ganti peran** lewat `RoleChip`, lalu `RoleSwitchSheet`. Navigasi dan warna berubah (240 ms), dengan haptic ringan dan snackbar "Sekarang sebagai Pekerja".
  - Menambah peran pekerja membuka langkah tambahan onboarding: jenis pekerjaan, hari tersedia, dan video.
  - Verifikasi KTP dipakai bersama, sehingga tidak diulang.
- **Deep link dari push:** `pramu://ajuan/{id}`, `pramu://pekerjaan/{id}`, `pramu://tagihan/{id}`, `pramu://pesan/{id}`.
  - Jika tujuan milik peran lain, aplikasi pindah peran dulu.
  - Jika sesi habis, aplikasi meminta masuk lalu kembali ke tujuan.
- **Android:** predictive back aktif. Tombol kembali sistem di wizard kembali satu langkah, bukan keluar dari wizard.
- **Tablet ≥ 840 dp:** `NavigationRail`, lalu dua panel daftar dan detail untuk Pesan dan Job.

## 3. Kamera dan berkas

### 3.1 KTP dan swafoto

- **Bingkai panduan:** persegi panjang untuk KTP, oval untuk wajah. Deteksi blur dan silau di perangkat sebelum unggah, dengan pesan "Foto buram, coba di tempat terang".
- **Liveness** memakai SDK penyedia (PRD §7.4), dibungkus layar persiapan berisi 3 ikon: lepas kacamata gelap, cahaya cukup, wajah di dalam oval.
- **Layar aman:**
  - Android memakai `FLAG_SECURE`. iOS menyembunyikan konten di app switcher.
  - Gambar tidak disimpan ke galeri. Berkas sementara ada di penyimpanan privat aplikasi dan dihapus setelah unggah berhasil atau dibatalkan.
- **Nomor KTP tidak diketik** pengguna, karena NIK dibaca oleh OCR.

### 3.2 Video perkenalan (H-7)

```
┌────────────────────────────────────┐
│ ←  Video perkenalan   Langkah 5/6  │
│ Video membantu majikan mengenalmu  │
│ sebelum menyetujui.                │
│ Contoh yang bisa kamu ucapkan:     │
│ 1. "Nama saya {Siti}, dari {Kebayoran Baru}."│
│ 2. "Saya biasa {masak dan mengasuh │
│    anak}, sudah {5} tahun."        │
│ 3. "Saya bisa mulai {hari Senin}." │
│ ⚠ Jangan sebut nomor HP atau akun  │
│   media sosial.                    │
│ [        Mulai merekam          ]  │
└────────────────────────────────────┘
```

Layar rekam:
- Kamera depan, bingkai wajah, dan penghitung waktu besar "0:42 / 1:00". Rekaman berhenti otomatis di 60 detik.
- Naskah contoh bisa ditampilkan di atas pratinjau sebagai teleprompter, dan bisa disembunyikan.
- Setelah merekam: pratinjau dengan tombol **Rekam ulang** dan **Pakai video ini**.

Unggah:
- Video dikompresi di perangkat ke 720p (target ≤ 20 MB, batas server 50 MB).
- Unggahan berjalan di latar belakang dan bisa dilanjutkan jika koneksi putus. Progres tampil di kartu Beranda.
- Pekerja bisa lanjut ke langkah berikutnya selama unggah. Profil pekerja baru tampil di pencarian setelah video selesai diunggah.
- Video bisa diganti kapan saja dari Akun. Video lama tetap tampil sampai video baru selesai diunggah.

### 3.3 Foto diri dan foto rumah

Foto diri setengah badan memakai bingkai bahu. Foto rumah diambil dari kamera, dengan opsi galeri. Ukuran dikompresi ke maksimal 5 MB sebelum unggah (PRD §7.3).

## 4. Izin perangkat

| Izin | Kapan diminta | Penjelasan sebelum dialog sistem |
|---|---|---|
| Kamera | Saat menekan "Ambil foto KTP" | "Kamera dipakai untuk foto KTP dan wajah. Foto tidak disimpan di galeri." |
| Mikrofon | Saat menekan "Mulai merekam" video | "Mikrofon dipakai untuk suara video perkenalan." |
| Lokasi | Saat memilih pin rumah atau lokasi job | "Lokasi dipakai untuk menghitung jarak. Pihak lain hanya melihat kecamatan sampai disepakati." |
| Notifikasi | Setelah ajuan pertama | "Agar kamu tidak melewatkan ajuan dan batas waktu." |
| Foto/galeri (simpan) | Saat menekan "Simpan QR ke galeri" | "QR disimpan agar bisa dipindai dari aplikasi bank atau e-wallet di HP ini." |

Jika izin ditolak, tampilkan `PermissionRationaleCard` dengan tombol "Buka Pengaturan", dan sediakan jalan alternatif bila ada (misalnya geser pin manual di peta).

## 5. Data offline dan sinkronisasi

| Data | Perilaku offline |
|---|---|
| Draf job, draf keberatan, pesan chat belum terkirim | Disimpan lokal, dikirim saat online (pesan dengan status "Menunggu koneksi") |
| Beranda, daftar job, pekerjaan berjalan | Tampil dari cache dengan `OfflineBanner` dan jam pembaruan terakhir |
| Aksi Setujui, Bayar, Batalkan, dan aksi tercatat lain | **Tidak** bisa offline. Tombol nonaktif dengan teks "Butuh koneksi" |
| Hitung mundur | Tetap berjalan dari waktu server terakhir yang diketahui. Saat online, disinkronkan ulang |

Semua aksi yang mengubah status mengirim kunci idempoten (PRD §24), sehingga mengirim ulang setelah koneksi putus aman.

## 6. Pembayaran di aplikasi

- Metode satu-satunya: **QRIS dinamis** (PRD §18.1, K-106). QR dirender di aplikasi dari `qr_payload` yang dikirim API. Tidak ada halaman gateway atau WebView.
- **Simpan QR ke galeri:** gambar PNG dengan nominal dan nama "Pramu" di bawah QR, karena pengguna sering membayar dari ponsel yang sama. Penyimpanan memakai izin foto/galeri, yang diminta saat tombol ditekan.
- Kecerahan layar dinaikkan sementara selama QR tampil, agar mudah dipindai dari perangkat lain.
- Layar S-11 menunggu webhook (Brief semua platform §8.2) lewat Reverb, dengan polling 5 detik sebagai cadangan.
- Jika pengguna menutup aplikasi saat membayar, Beranda menampilkan kartu "Pembayaran sedang diproses" sampai webhook tiba.

## 7. Platform

| Elemen | Android | iOS |
|---|---|---|
| Dasar komponen | Material 3 bertoken (`app_ui`) | Sama |
| Transisi | Predictive back | Swipe-back dari tepi |
| Dialog konfirmasi | `ConfirmDialog` | Sama, bentuk adaptif |
| Pemilih tanggal dan jam | Material | `CupertinoDatePicker` di sheet |
| Haptic | Ringan pada Setujui, Bayar, ganti tab | Sama |
| Orientasi | Portrait di ponsel | Portrait di ponsel |

## 8. Skala teks dan perangkat kelas bawah

- Uji di skala 100%, 130%, dan 200%. Kartu tindakan, tombol Setujui, dan hitung mundur tidak boleh terpotong. Bentuk `Wrap` dan tinggi minimum, bukan tinggi tetap.
- Acuan perangkat: Android RAM 3 GB, layar 360×800.
  - Daftar memakai paginasi 20 item.
  - Gambar profil berupa thumbnail.
  - Video tidak diputar otomatis.
- Ukuran APK target < 30 MB, font di-subset (Design System §5).

## 9. Perubahan di kode `app_ui`

| Bagian | Perubahan |
|---|---|
| `StatusChip` / `StatusDomain` | Ganti domain menjadi `booking`, `penugasan`, `job`, `tagihan`, `verifikasi` (Brief semua platform §9). Hapus `period`, `payout`, `application`, `listing`, `interview` |
| `TrustCard` | Hapus parameter `skckVerified`. Tambahkan jumlah pembatalan 120 hari dan badge peringatan (PRD §13) |
| `LedgerTimeline`, `LedgerMini`, `FeeBreakdown`, `MoneySafeIllustration` | Tidak dipakai di model baru. Hapus setelah fitur lama dibongkar (K-47) |
| `AppRole` | `seeker` → majikan, `assistant` → pekerja. Nama enum boleh diganti saat fitur dibangun ulang |
| Komponen baru | `JobTypeCards`, `ChipSelect`, `SuggestField`, `RangeStepper`, `ActionCard`, `CountdownText`, `CandidateCard`, `JobCard`, `ApprovalSteps`, `PayerNote`, `LockedRow`, `ConsequenceDialog`, `VideoRecorder` (Brief semua platform §10 dan §3.2 di atas) |

Setiap komponen baru masuk ke `DesignGalleryScreen` dan diuji golden di terang/gelap dan skala 130% (Design System §6).

## 10. Uji khusus aplikasi

- Liveness dan video di 3 perangkat Android kelas bawah dan 1 iPhone.
- Unggah video dengan koneksi diputus di tengah jalan: harus bisa dilanjutkan.
- Deep link dari push untuk peran lain: harus pindah peran dan membuka layar yang benar.
- Skala teks 200% pada S-05, S-10, dan S-12.

## 11. Dua bahasa (PRD §3.4)

Aturan tampilan dan istilah ada di Brief semua platform §11.1. Di aplikasi:

- **Mekanisme:** `flutter_localizations` dan `gen-l10n`. Berkas `lib/l10n/app_id.arb` dan `app_en.arb`, dengan `app_id.arb` sebagai templat. `MaterialApp(supportedLocales: [id, en], localizationsDelegates: …)`.
- **Akses teks:** semua teks lewat `context.l10n.namaKunci`. Lint kustom atau `grep` di CI menolak string literal berhuruf di `lib/features/**`.
- **Penyimpanan:**
  - Pilihan disimpan di `shared_preferences` sebelum masuk.
  - Setelah masuk, pilihan disinkronkan ke `users.bahasa` lewat API.
  - Perubahan di perangkat lain berlaku saat aplikasi dibuka berikutnya.
- **Ganti bahasa saat berjalan:** locale disimpan di state global (Riverpod), sehingga `MaterialApp` dibangun ulang tanpa restart dan tanpa kehilangan isi form. Header `Accept-Language` ikut berubah untuk permintaan API berikutnya.
- **Format:** `intl` `NumberFormat`/`DateFormat` dengan locale aktif. `core/money` menerima locale.
- **Komponen `app_ui`:** default label bahasa Indonesia di komponen (misalnya `PrivacyNote`) diganti parameter wajib, agar teks selalu datang dari ARB.
- **Golden test:** `tool/screenshots` dijalankan untuk `id`, `en`, dan bahasa semu `en-XA` (+40%) di skala teks 100% dan 130%.

## 12. Keputusan terbuka

1. Penyedia OCR dan liveness, beserta ukuran SDK-nya (memengaruhi ukuran APK).
2. Batas kompresi video final setelah uji kualitas di perangkat kelas bawah.
