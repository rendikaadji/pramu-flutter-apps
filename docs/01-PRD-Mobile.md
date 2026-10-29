---
tags: [proyek, mobile, flutter, prd, android, ios]
status: draft
tanggal: 2026-10-28
versi: 1.1
---

# 01 — PRD Mobile (Flutter) — Asisten Marketplace
> **USANG (29 Oktober 2026):** dokumen ini mengikuti model lama (lowongan, lamaran, wawancara, SKCK, escrow). Sumber aturan produk sekarang satu: [PRD Web v1.1](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) dan [Skema Database](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/12-Skema-Database.md) di repo pramu-laravel-web. Dokumen ini ditulis ulang per modul saat app dibangun ulang (keputusan K-47).

> **Perubahan lingkup (2026-10-28, v1.1):** penampungan dana (escrow) **dihapus**: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, sengketa dana, dan potongan platform 10%. Yang tetap: lowongan (dengan biaya tayang), lamaran, wawancara, kesepakatan, kontrak (jadwal periode tanpa uang), chat, rating, cari asisten, undangan, laporan. Gaji dibayar langsung antara pemberi kerja dan asisten; satu-satunya uang di platform = biaya tayang lowongan.
> Turunan [[PRD-v1]] (apa) + [[Spec-Teknis-v1]] (bagaimana API). Dokumen ini hanya sisi **app Flutter**: layar, perilaku klien, platform. AC bisnis lengkap tetap di PRD-v1 §5; di sini hanya AC **sisi klien**. Rencana kerja: [[Rencana-Kerja-v1]]. Penanda: **[MVP]** / **[R2]** / 🟡 = perlu konfirmasi.
> Keadaan kode: [[09-Arsitektur-App]].

## 1. Ringkasan

1 app Flutter (Android + iOS), 1 akun bisa 2 role (Pencari / Asisten), `active_role` menentukan navigasi & layar. Backend = Laravel API `/api/v1` (OpenAPI = sumber kebenaran). Dev B (seleksi) + Dev C (transaksi & komunikasi).

## 2. Persona

| Persona | Konteks pakai | Kebutuhan di app | Hambatan yang harus ditangani |
|---|---|---|---|
| **Pencari** | Ibu/keluarga, ponsel mid-range, sibuk | Posting lowongan, saring pelamar, wawancara, nilai | Takut penipuan; ingin kesepakatan kerja yang jelas |
| **Asisten** | Ponsel entry-level, kuota terbatas, literasi digital beragam | Profil kredibel, lamar cepat, kesepakatan kerja jelas | Foto KTP buram, jaringan lemah, layar kecil |
| (Admin/Super admin) | Bukan di app mobile (React) | — | — |

## 3. Navigasi per role 🟡 (final di dokumen UIUX)

| Role | Tab utama |
|---|---|
| Pencari | Beranda · Lowongan saya · Chat · Booking · Akun |
| Asisten | Cari kerja · Lamaran · Chat · Akun |
Switch role: Akun → Ganti peran (AUTH-2); stack navigasi di-reset saat switch.

## 4. User story & AC sisi klien

Konvensi: AC klien = apa yang **harus tampil/terjadi di app**. Semua teks UI Indonesia; waktu tampil WIB; uang `Rp25.000` (format satu tempat).

### AUTH — Akun & role ([[PRD-v1]] §5.1)
| ID | User story | AC klien | Fase |
|---|---|---|---|
| AUTH-1 | Sebagai pengguna baru saya daftar dengan HP+email+password dan OTP | Form validasi lokal (HP 08/+62, email, password ≥ 8); layar OTP 6 digit, hitung mundur 5 menit, tombol "Kirim ulang" dinonaktifkan sampai timer habis; 429 → pesan "terlalu banyak percobaan", tampil sisa tunggu bila ada | MVP |
| AUTH-2 | Saya pilih role saat onboarding & bisa ganti | Onboarding 1 layar pilih role; Akun → "Tambah/ganti peran" memanggil `/me/roles`, `/me/switch-role`; UI berganti tanpa login ulang | MVP |
| AUTH-3 | Login/logout/lupa password | Token di secure storage; logout memanggil `/auth/logout` lalu hapus token+cache lokal walau request gagal; 401 → alur refresh/relogin (lihat §8) | MVP |

### VER — Verifikasi ([[PRD-v1]] §5.2)
| ID | User story | AC klien | Fase |
|---|---|---|---|
| VER-1 | Saya unggah KTP + selfie pegang KTP | Kamera dengan overlay bingkai KTP; kompres ≤ 5 MB (jpg); preview + "Ulangi"; multipart upload dengan progress & retry; status `pending/verified/rejected` + alasan tolak; tombol upload ulang saat rejected; aksi posting/lamar terkunci dgn banner "Verifikasi dulu" bila belum `verified` (server tetap 403) | MVP |
| VER-2 | Saya diberi tahu hasil review | Push + badge di Akun; buka langsung ke layar status | MVP |
| VER-3 | Asisten upload SKCK per lowongan | Tombol Lamar terkunci + penjelasan jika lowongan `require_skck` & SKCK belum ada; SKCK tersimpan dipakai ulang; picker foto/PDF ≤ 5 MB | MVP |

### PRO — Profil ([[PRD-v1]] §5.3)
| ID | AC klien | Fase |
|---|---|---|
| PRO-1 | Form profil asisten: foto, ≥1 kategori, pengalaman, keahlian, tarif+tipe periode, kota, ketersediaan; kategori & kota wajib; status "Tampil publik hanya jika terverifikasi" jelas | MVP |
| PRO-2 | Profil publik: badge verifikasi, rating+jumlah review, pekerjaan selesai; **tidak** menampilkan HP/alamat (server tidak mengirim; klien tidak menampilkan field kontak sebelum kontrak dibuat) | MVP |

### LST — Lowongan ([[PRD-v1]] §5.4)
| ID | AC klien | Fase |
|---|---|---|
| LST-1 | Form multi-langkah (kategori → detail → periode/budget → SKCK & screening); draft disimpan di server (`draft`); validasi inline dari `error.fields` | MVP |
| LST-2 | Tombol "Bayar & tayangkan" (biaya tayang) → `/listings/{id}/pay` → buka `invoice_url` di WebView (§6.4); status `awaiting_payment` → polling/refresh sampai `open` (sumber kebenaran = webhook, bukan callback klien) | MVP |
| LST-3 | Daftar pelamar, tutup lowongan (konfirmasi dialog) | MVP |
| LST-4 | Daftar + filter (kategori, kota, tarif, periode, rating), pagination infinite scroll, pull-to-refresh, empty state | MVP |

### APP / INT — Lamaran & wawancara ([[PRD-v1]] §5.5)
| ID | AC klien | Fase |
|---|---|---|
| APP-1 | Form lamar: pesan, usulan tarif (input rupiah integer), jawaban screening; setelah kirim tombol jadi "Sudah dilamar" + opsi Tarik lamaran; 409 → pesan state | MVP |
| APP-2 | Pencari: kartu pelamar (profil kepercayaan), jawaban screening, aksi Shortlist/Tolak/Terima | MVP |
| INT-1 | Pencari pilih ≥1 slot (date/time picker, WIB); pelamar Konfirmasi/Usul ulang; status & pengingat (push 1 jam) | MVP |
| INT-2 | Tombol "Gabung" membuka `meeting_url` lewat `url_launcher` (aplikasi Meet/browser); error `MEET_CREATE_FAILED` (502) → pesan + "Coba lagi", interview tetap `proposed` | MVP |
| INT-3 | Form catatan & skor (3 aspek 1–5), hanya muncul bagi pencari; tak ada UI evaluasi di sisi asisten | MVP |
| INT-4 | Opsi "lewati wawancara" per lowongan → langsung Terima | MVP |

### CHT — Chat ([[PRD-v1]] §5.6)
| ID | AC klien | Fase |
|---|---|---|
| CHT-1 | Daftar percakapan, bubble, indikator baca, kirim via REST (sumber kebenaran) + terima via Reverb private channel `private-conversation.{ulid}`; fallback polling bila WS putus; pesan optimistik dgn status `mengirim/terkirim/gagal` + retry | MVP |
| CHT-2 | Teks yang dikembalikan server sudah disamarkan; klien menampilkan apa adanya (jangan "memperbaiki") + info banner "kontak disamarkan sampai kontrak dibuat" | MVP |
| CHT-3 | Gambar/dokumen di chat | R2 |

### BKG — Kesepakatan & booking ([[PRD-v1]] §5.7)
| ID | AC klien | Fase |
|---|---|---|
| BKG-1 | Layar kesepakatan: usul/counter/setuju (tarif, jumlah periode, siklus gaji, mulai); tanpa rincian fee; tombol Setuju hanya pada versi terbaru (`version`); kedua setuju → booking muncul | MVP |
| BKG-2 | Detail booking + jadwal periode (status, nominal, tanggal) tanpa tagihan; status periode mengikuti waktu | MVP |

### PAY — Biaya tayang (satu-satunya pembayaran)
| ID | User story | AC klien | Fase |
|---|---|---|---|
| PAY-1 | Pencari membayar biaya tayang lowongan | Rincian Rp25.000 dari server; Bayar → `Idempotency-Key` (UUID per niat bayar, dipakai ulang bila retry) → `invoice_url` → browser dalam aplikasi → kembali ke app (`/pay/return?listing=<ulid>`) → cek status; `open` hanya setelah server bilang | MVP |
| PAY-2 | Tidak ada pembayaran gaji di app | Kontrak hanya menampilkan jadwal periode (terjadwal / berjalan / selesai / dibatalkan) dan nominal kesepakatan apa adanya; tanpa tombol bayar, saldo, atau konfirmasi selesai | MVP |
| PAY-3 | Batalkan kontrak | Alasan wajib; konfirmasi dialog; periode belum selesai ikut batal; **tanpa refund** (tidak ada dana tertahan); 409 → muat ulang | MVP |

### RAT — Rating ([[PRD-v1]] §5.8)
| ID | AC klien | Fase |
|---|---|---|
| RAT-1 | Form bintang 1–5 + komentar opsional; setelah kirim tak bisa diedit; countdown 7 hari; deep link dari pengingat (hari 1/4/6) | MVP |
| RAT-2/3 | Review auto ditandai "Otomatis" (`is_auto`); rating lawan disembunyikan sampai milik sendiri terkirim atau 7 hari lewat (server yang menentukan, klien hanya render `revealed`) | MVP |

### NTF — Notifikasi ([[PRD-v1]] §5.9)
| ID | AC klien | Fase |
|---|---|---|
| NTF-1 | Izin notifikasi diminta kontekstual (setelah daftar, bukan saat start); token FCM dikirim ke `/me/devices` saat login & saat `onTokenRefresh`; daftar in-app + tandai terbaca; tap push (foreground/background/terminated) → rute ke layar terkait (§6.2) | MVP |

### PRV — Privasi & laporan ([[PRD-v1]] §5.10)
| ID | AC klien | Fase |
|---|---|---|
| PRV-2 | Form laporan/dispute: alasan + bukti pilihan sendiri (foto) | MVP |
| PRV-3 | Tombol "Bagikan percakapan ini ke admin" dgn dialog persetujuan eksplisit (7 hari, dapat dicabut otomatis saat kasus ditutup); pihak lawan diberi tahu (server) | MVP |
| PRV-1/4 | Tidak ada UI admin di app; dokumen KTP/SKCK hanya di-upload, tidak pernah ditampilkan ulang lewat URL publik | MVP |

## 5. MVP vs R2 (mobile)

| MVP (3 minggu) | R2 |
|---|---|
| Semua ID di atas kecuali CHT-3 | Gambar/dokumen di chat, dispute in-app lengkap, amendment kontrak, bayar tahunan di muka, geo radius, E2E encryption, boost/paket listing, badge rekomendasi, bahasa selain Indonesia, tablet layout, tema gelap 🟡, biometric unlock 🟡 |

## 6. Kebutuhan platform

| Area | Kebutuhan | Catatan |
|---|---|---|
| Versi OS | Android 8+ (API 26) 🟡, iOS 14+ 🟡 (PRD §10 butir 6); `minSdk`/`IPHONEOS_DEPLOYMENT_TARGET` mengikuti, plus minimum yang disyaratkan plugin terpilih | Verifikasi saat `flutter pub get` |
| 6.1 Kamera/galeri | KTP + selfie + SKCK + foto profil + bukti laporan. Plugin kandidat: `image_picker` (cukup MVP) atau `camera` (overlay kustom) 🟡 pilih | Android: izin `CAMERA` hanya bila pakai `camera`; iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` wajib berisi alasan Indonesia. Kompres sebelum upload; hapus file sementara setelah upload; jangan simpan KTP di galeri |
| 6.2 Push FCM | `firebase_messaging` + `firebase_core`. Android 13+: izin runtime `POST_NOTIFICATIONS`. iOS: APNs auth key (.p8) diunggah di Firebase, capability Push Notifications + Background Modes (Remote notifications). Payload minimal tanpa isi chat (Spec §8) → payload membawa `type` + `id` (ULID) untuk routing; isi diambil dari API | Handler background top-level; 3 status (foreground/background/terminated) wajib diuji |
| 6.3 Deep link | Return dari Xendit untuk biaya tayang (`success_url`/`failure_url`) & dari push. Opsi: custom scheme (`/pay/return?listing=<ulid>`) atau App Links/Universal Links (butuh domain + `assetlinks.json` / `apple-app-site-association`). Paket kandidat: `app_links` atau `go_router` deep linking 🟡 | Return URL **hanya pemicu refresh**; jangan percaya parameter sukses di URL |
| 6.4 WebView bayar | `webview_flutter` (atau `flutter_inappwebview` 🟡). Buka hanya `https` host Xendit/allowlist; tangkap navigasi ke `success_url`/`failure_url` → tutup WebView → cek status ke API; tombol tutup/kembali aman; jangan inject JS; tidak menyimpan cookie sensitif | Alternatif: browser eksternal (`url_launcher`) + deep link — lebih sederhana, UX kurang mulus |
| 6.5 Realtime | Reverb (protokol kompatibel Pusher). Klien kandidat: `pusher_channels_flutter` 🟡 atau `web_socket_channel` manual 🟡 — **spike hari 1 minggu 1** (Rencana-Kerja C) | Auth channel privat via endpoint broadcasting Laravel dengan Bearer token |
| 6.6 Permission | Minta saat dibutuhkan + pra-penjelasan (rationale screen) + jalur "Buka Pengaturan" bila ditolak permanen | Kamera, galeri, notifikasi; lokasi **tidak** dipakai MVP (geo = R2) |
| 6.7 Penyimpanan lokal | Token: `flutter_secure_storage` (Keychain/Keystore). Non-sensitif (role aktif, flag onboarding): `shared_preferences`. Android: `android:allowBackup="false"` atau exclude secure prefs 🟡 | Jangan simpan KTP/chat plaintext di disk |
| 6.8 Bahasa/waktu | `intl` locale `id_ID`; zona `Asia/Jakarta`; UTC dari API di-convert di satu helper | |
| 6.9 Layar | Portrait only MVP 🟡; teks mengikuti text scale sistem (uji 1.3x) | |

## 7. Offline & error behavior

| Situasi | Perilaku |
|---|---|
| Tanpa internet saat buka | Tampilkan data cache terakhir (read-only: profil, daftar lowongan/lamaran) + banner "Offline"; aksi tulis dinonaktifkan |
| Request gagal (timeout/5xx) | Pesan ramah + "Coba lagi"; GET boleh auto-retry 1-2x (backoff); **POST pembayaran biaya tayang tidak auto-retry tanpa Idempotency-Key yang sama** |
| 401 | Sesi habis → bersihkan token, ke layar login, simpan tujuan untuk dilanjutkan; (refresh token **tidak ada di Spec** — Sanctum token tunggal; 🟡 konfirmasi apakah ada rotasi) |
| 403 `verified` | Arahkan ke layar verifikasi |
| 409 `*_INVALID_STATE` | Muat ulang entitas, tampilkan state terbaru ("Status sudah berubah") |
| 422 | Petakan `error.fields` ke error di field form |
| 429 | Tampilkan "coba lagi nanti"; nonaktifkan tombol sementara |
| WebSocket putus | Banner kecil, reconnect eksponensial, fallback polling REST; setelah reconnect, sinkron pesan > id terakhir |
| Bayar biaya tayang: app dimatikan saat di browser | Saat dibuka lagi, layar bayar cek status lowongan ke server (idempoten), bukan bergantung pada deep link |
| Upload gagal | Pertahankan file lokal sementara, tombol "Kirim ulang" |
| Versi app terlalu lama | Server kirim 426/kode khusus 🟡 → layar "Perbarui aplikasi" (pakai header `X-App-Version`) |

Header yang dikirim setiap request: `Authorization`, `Accept-Language: id`, `X-App-Version`, `X-Device-Id` (UUID lokal), `Idempotency-Key` untuk pembayaran biaya tayang.

## 8. NFR mobile 🟡 (target awal, disepakati kemudian)

| Area | Target | Cara ukur |
|---|---|---|
| Cold start (mid-range) | ≤ 3 dtk sampai layar interaktif 🟡 | `flutter run --profile` + DevTools / Firebase Performance 🟡 |
| Frame | 60 fps, jank < 1% frame di list utama 🟡 | DevTools Performance |
| Ukuran | APK/AAB unduhan ≤ 40 MB 🟡 | `flutter build apk --analyze-size` / `--split-per-abi` |
| Crash-free sessions | ≥ 99,5% 🟡 | Crashlytics/Sentry 🟡 |
| Memori | Tidak ada leak di list gambar/chat | DevTools Memory |
| Jaringan | Request timeout 15 dtk (30 dtk upload); list ≤ 50 item/halaman (Spec §2) | |
| Aksesibilitas | `Semantics` label di tombol ikon & input; kontras AA; tap target ≥ 48dp | `flutter test` semantics + TalkBack/VoiceOver manual |
| Keamanan | Lihat dokumen keamanan mobile (disiapkan terpisah); minimal: secure storage, TLS, tanpa log PII, `FLAG_SECURE` di layar KTP 🟡 | |

## 9. Rilis ke store

| Item | Play Store | App Store |
|---|---|---|
| Akun | Google Play Console (biaya sekali) | Apple Developer Program (tahunan) — siapkan hari 1 (PRD §8) |
| Jalur awal | Internal testing → Closed → Production | TestFlight → App Review |
| Signing | Upload key + Play App Signing; keystore **tidak di-commit** | Certificates/profiles (manual atau fastlane match 🟡) |
| Akun demo reviewer | 2 akun di staging/production-demo: Pencari `verified` & Asisten `verified` dengan data contoh; OTP **tetap** untuk akun demo (kode di catatan review) atau bypass terkontrol 🟡 — diputuskan dengan Dev A | Wajib disediakan di App Review Notes; sertakan cara uji pembayaran (sandbox) |
| Privacy | Data safety form: data yang dikumpulkan (nama, HP, email, foto KTP, lokasi kota, ID perangkat, notifikasi), enkripsi in-transit, hapus akun | Privacy Nutrition Label (Contact Info, Identifiers, User Content, Financial Info hanya untuk riwayat biaya tayang, Usage); `NSUsageDescription` per izin |
| Kebijakan | URL privacy policy & ToS (dari LND-1), kontak support | + **hapus akun in-app** (syarat App Store untuk app dengan pembuatan akun) 🟡 endpoint belum ada di Spec |
| Konten | Ikon, splash, screenshot (2 ukuran min), deskripsi ID | Idem + age rating |
| Pembayaran | Hanya biaya tayang lowongan (layanan digital) lewat gateway; 🟡 **verifikasi kebijakan Apple/Google** apakah wajib IAP; siapkan penjelasan di review notes | |
| Catatan | App Review bisa beberapa hari di luar 3 minggu (PRD §8) → kirim build di minggu 3 hari 1-2 | |

## 10. Metrik (mobile; turunan PRD §2 🟡)

| Metrik | Target 🟡 | Sumber |
|---|---|---|
| Registrasi selesai (OTP valid / mulai daftar) | ≥ 60% | analytics 🟡 |
| Verifikasi terkirim (upload selesai / daftar) | ≥ 70% | |
| Lowongan → pembayaran fee sukses | ≥ 50% | |
| Lamar → shortlist | dipantau | |
| Kontrak selesai / kontrak dimulai | dipantau | |
| Crash-free sessions | ≥ 99,5% | Crashlytics 🟡 |
| Push opt-in | ≥ 70% | |
Analytics tidak boleh memuat PII/isi chat. Tool analytics belum diputuskan 🟡 (Firebase Analytics / PostHog / tanpa).

## 11. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Klien Reverb di Flutter belum teruji | Chat tidak realtime | Spike minggu 1; fallback polling REST sudah di Spec §8 |
| Alur bayar biaya tayang + deep link (iOS/Android berbeda) | Pembayaran "menggantung" di UI | Sumber kebenaran = status server; layar cek status; uji di perangkat fisik |
| Push iOS (APNs) salah konfigurasi | Notifikasi tak masuk iOS | Checklist di [[04-Debug-Playbook-Mobile]] §FCM |
| Review store / kebijakan pembayaran | Rilis telat | Build awal minggu 3; akun demo; jawab kebijakan lebih dulu |
| 2 dev mobile berbagi fondasi (HTTP client, state) | Konflik | Hari 1 sepakati struktur (feature-first) dan API client tunggal ([[06-Refactor-DeadCode-Mobile]]) |
| Foto KTP buruk | Banyak reject | Overlay, deteksi blur sederhana 🟡, tips di UI |
| Tanpa pendapatan komisi (fee 10% dihapus) | Model bisnis | Pendapatan = biaya tayang; putuskan model tambahan 🟡 |

## 12. Pertanyaan terbuka (mobile)

1. State management & router (Riverpod/Bloc, go_router?) — Spec §12.3.
2. Klien realtime: paket mana yang cocok dengan Reverb?
3. Deep link: custom scheme vs App/Universal Links (butuh domain final, PRD §10.1).
4. Hapus akun in-app: endpoint & kebijakan retensi (syarat store).
5. Refresh token / masa berlaku token Sanctum perangkat.
6. Analytics & crash reporting: tool apa, persetujuan UU PDP.
7. Akun demo reviewer: OTP bypass atau nomor khusus?
8. Kebijakan store untuk pembayaran jasa via gateway di luar IAP.
9. Siapa desainer; dokumen UIUX terpisah (02).
10. Min OS final (PRD §10.6).

Dokumen terkait: [[04-Debug-Playbook-Mobile]] · [[05-E2E-Test-Mobile]] · [[06-Refactor-DeadCode-Mobile]] · [[07-Git-Commit-Mobile]] · [[08-Skill-Mobile]]
