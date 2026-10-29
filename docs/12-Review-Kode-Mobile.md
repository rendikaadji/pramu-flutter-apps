---
tags: [proyek, mobile, flutter, review, kode]
status: draft
tanggal: 2026-10-10
versi: 1.0
---

# 12 — Review Kode Mobile (branch feat/core-app-mvp)
> **Kode lama (29 Oktober 2026):** dokumen ini menggambarkan kode yang masih ada. Domain app akan dibangun ulang mengikuti [PRD Web v1.3](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) dan [Skema Database](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/12-Skema-Database.md) di repo pramu-laravel-web (keputusan K-47). Kontrak API berubah total dan ID berganti dari ULID ke UUIDv7.

> **Perubahan lingkup 2026-10-28:** penampungan dana (escrow) dihapus: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, potongan platform 10%, dan sengketa dana **tidak berlaku lagi** (layar M-74..76, M-80..83). Kesepakatan, kontrak (tanpa uang), biaya tayang lowongan, dan rating tetap. Acuan terbaru: [[01-PRD-Mobile]] dan [[09-Arsitektur-App]].

> Mode baca saja. `flutter analyze`: **No issues found**. `flutter test`: **256 test lulus**. Cakupan: pola lintas fitur (state, error, timer, idempotency, paginasi), bukan setiap layar baris-per-baris. Rujukan: [[09-Arsitektur-App]] · [[10-Design-System-App]] · [[06-Refactor-DeadCode-Mobile]] · [[07-Git-Commit-Mobile]].

Yang sudah baik (terverifikasi): tidak ada impor lintas `presentation` fitur; tidak ada warna/fontSize hardcode di `features/`; semua tampilan uang lewat `formatRupiah` (tak ada `double` uang, tak ada hitung fee di UI); aksi status lewat `allowedActions`/`actionsFor`; Idempotency-Key per niat (pay dan payout) dirotasi hanya pada penolakan pasti; semua Timer dibatalkan di `dispose`/`onDispose`; Key di `test_keys.dart` tidak duplikat; semua `Routes.*` punya GoRoute.

## 1. Bug dan logika (urut severity)

| # | Sev | Lokasi | Masalah dan dampak | Perbaikan |
|---|---|---|---|---|
| B1 | Sedang | `lib/features/payment/presentation/state/payment_state.dart:63-68` | Saat jaringan putus, retry memanggil `refresh()` yang mereset `_polls = 0`. Batas `maxPolls` (24) tak pernah tercapai: polling tiap 5 dtk tanpa henti selama offline dan `state` diganti `AsyncError` tiap putaran (M-75 berkedip error). | Jangan reset `_polls` di jalur retry otomatis: pisahkan `refresh()` (manual, reset) dari `_poll()` (otomatis, `_polls++`). Tambah cek `ref.mounted` sebelum `state = ...` di `refresh()`. |
| B2 | Sedang | `lib/features/listing/presentation/screens/listing_pay_screen.dart:`88` (`_pay` ke `_startPolling`) | `act()` mengembalikan `true` walau widget sudah dispose; `if (done) _startPolling();` memanggil `setState` setelah dispose bila pengguna keluar saat `pay()` berjalan. | `if (done && mounted) _startPolling();` |
| B3 | Sedang | `lib/features/listing/presentation/widgets/paged_list.dart:36` dan `state/paged_notifier.dart:69` | Listener scroll memanggil `onLoadMore` tiap notifikasi scroll saat `extentAfter < 300`. Setelah `loadMore` gagal (cursor tetap) tiap gerakan scroll memicu request gagal lagi (badai request saat offline; tiap GET masih retry 3x di `ApiClient`). | Di `loadMore()` keluar bila `s.error != null`; retry hanya via tombol Coba lagi atau refresh. |
| B4 | Rendah-sedang | `lib/features/chat/data/api_chat_repository.dart` (`send`) dan `chat_state.dart` (`_deliver`, `retry`) | Kirim pesan tanpa Idempotency-Key. Bila server sukses tapi respons hilang (timeout), bubble `failed`; ulangi membuat pesan ganda. | Kirim `client_id` per bubble lokal (dipakai ulang saat retry) via `ApiClient.idempotent`; perlu kontrak backend. |
| B5 | Rendah | `lib/shared/app_ui/api_error_view.dart:267-281` (`ApiActionMixin.act`) | Setelah `await showDialog` Muat ulang, `onConflict()` dipanggil tanpa cek `mounted`; callback umumnya `ref.invalidate(...)` pada widget yang sudah dispose. | Tambah `if (!mounted) return false;` sebelum `onConflict()`. |
| B6 | Rendah | `api_error_view.dart:261` | Cooldown 429 tetap 15 dtk, tak membaca `Retry-After`; OTP (`otp_screen.dart:16`) punya pola sendiri. Dua pola 429. | Ambil `Retry-After` di `ApiException` bila ada, default 15 dtk. |
| B7 | Rendah | `lib/features/auth/presentation/screens/account_screen.dart:64-75` | `logout`: `sweepSensitiveFiles()` atau `push.deleteToken()` yang melempar non-ApiException (FCM nanti) membatalkan logout. Saat ini aman karena `NoopPushService`. | Bungkus langkah pra-logout `try/finally` agar `sessionProvider.logout()` selalu jalan (MOB-SEC-20). |
| B8 | Rendah | `listing_pay_screen.dart:94` | `Timer.periodic` dengan `_check()` async tanpa guard in-flight: respons lambat menumpuk request paralel. | Flag `_checking`, atau `Timer` sekali-jalan yang dijadwal ulang setelah selesai (seperti `PaymentStatusNotifier`). |
| B9 | Rendah | `lib/features/interview/presentation/screens/interview_detail_screen.dart:143` | Hitung mundur dihitung sekali saat build; tidak berdetak dan tombol Gabung tidak aktif otomatis saat jendela 15 mnt terbuka. | Timer 30 dtk (pola `confirm_complete_screen.dart:132`). |
| B10 | Rendah | `chat_state.dart` (`build` memanggil `repo.messages`) dan `api_chat_repository.dart:incoming` | Pesan dimuat sekaligus tanpa paginasi; `incoming` mulai dengan `after: null` sehingga polling pertama mengambil ulang seluruh daftar. | Paginasi mundur bila API mendukung; set `last` dari daftar awal. |

## 2. Konsistensi antar agent

| # | Lokasi | Temuan | Perbaikan |
|---|---|---|---|
| K1 | `shared/app_ui/api_error_state.dart`, `api_error_view.dart`, `error_state.dart` | Tiga lapis error muat. `ApiErrorState` (6 layar: notification, rating, report) dan `ApiErrorView` (listing, payment, wallet, `AsyncBody`) setara, tetapi `ApiErrorState` **tidak** menangani 403 `VERIFICATION_REQUIRED` (tombol Ke verifikasi). | Hapus `ApiErrorState`; ganti 6 pemakai dengan `ApiErrorView` atau `AsyncBody`. `ErrorState` cukup internal. |
| K2 | `rating_state.dart`, `notification_state.dart`, `wallet_state.dart` vs `listing/.../paged_notifier.dart` | Dua pola paginasi: `PagedNotifier` (listing/search) dan tiga state tulis-tangan (`ReviewsState`, `NotificationsState`, `TxState`) dengan perilaku error `loadMore` berbeda (wallet menelan error diam-diam, `wallet_state.dart:51`). `PagedNotifier` tinggal di `features/listing` sehingga fitur lain tak boleh memakainya. | Pindah `PagedNotifier`, `PagedState`, `PagedListView` ke `shared/` atau `core/`, migrasikan tiga state itu; atau seragamkan perilaku error. |
| K3 | `rating_screen.dart:28`, `report_form_screen.dart:40`, `report_status_screen.dart:41`, `share_consent.dart:44` | `_busy` manual vs `ApiActionMixin` (28 layar lain): tak ada cooldown 429, dialog 409, `ActionErrorBox` seragam (mis. `report_form_screen.dart:133` menangani 403 sendiri). `capture_step.dart:112` boleh tetap (bukan aksi API). | Pakai `ApiActionMixin`. |
| K4 | `lib/core/router/stub_route.dart`, `lib/core/widgets/placeholder_screen.dart` | **Kode mati**: tak ada pemakai di `lib/` maupun `test/`. | Hapus kedua file; perbarui `docs/09` bagian 2 dan 7 (menyebut stub). |
| K5 | `lib/core/test_keys.dart` | Key tak terpakai di `lib/` dan `test/`: `tabSearchJobs`, `agreementDone`, `walletHistoryOpen`, `verificationOpenSettings`, `offlineBanner`. Key lokal di luar `K`: `filter_rate` (`filter_sheet.dart:118`), `otp-box-i` (`otp_input.dart:92`), `otp-round` (`otp_screen.dart:138`): melanggar aturan 8 docs/09. | Hapus yang tak terpakai; pindahkan key lokal ke `K`. |
| K6 | `docs/09` bagian 3 butir 4 | Aturan jangan memakai status mentah di UI dilonggarkan de facto: sekitar 60 perbandingan status di presentation (mis. `booking_detail_screen.dart:89-141`, `home_state.dart:54-105`). Sebagian untuk banner (wajar). | Perjelas aturan: hanya **aksi** yang wajib via `allowedActions`; atau tambah getter domain (mis. `BookingStatus.isFrozen`). |
| K7 | `pubspec.yaml` | `cupertino_icons` tidak diimpor di `lib/` (sisa template; ikon pakai `lucide_icons_flutter`). Paket lain terpakai. | Hapus `cupertino_icons`. |
| K8 | `test/` | 111 pemakaian `pumpAndSettle` atau `pump(Duration)`; layar ber-`Timer.periodic` (polling) bergantung `stepDelay` mock. Hijau sekarang, risiko flaky bila mock berubah. | Audit test layar polling (M-15, M-34, M-75, M-61): `stepDelay = Duration.zero` dan `pump` terbatas. |

## 3. Ponytail / clean code

- **P1** File di atas 400 baris: `core/mock/mock_backend.dart` (1005, wajar untuk mock), `listing_wizard_screen.dart` (579: pisahkan 4 langkah jadi widget per langkah), `home_screens.dart` (427: dua beranda dalam satu file), `design_gallery_screen.dart` (402, dev-only; pastikan tak terpasang di rute produksi).
- **P2** Dua paginasi dan dua widget error = abstraksi ganda (K1/K2): pilih satu, hapus sisanya.
- **P3** `api_error_view.dart` (291 baris) memuat `AsyncBody`, `ListSkeleton`, `noRetry`, `popOrGo`, `ActionErrorBox`, mixin: nama file tak menggambarkan isi; pecah bila bertambah.
- **P4** `ApiErrorView` menampilkan kode error mentah ke pengguna akhir; cukup untuk debug atau Detail.

## 4. Aksesibilitas dan text scale

- Baik: `Semantics(liveRegion)` pada error, label Memuat, `RatingStars` berlabel, ada test skala teks 1,3x (listing_flow, verification).
- Perlu cek: hitung mundur (B9) tak diumumkan; tap target `TextButton` kecil (Tarik semua saldo, `payout_screen.dart:164`); tambah `meetsGuideline` (labeledTapTargetGuideline, androidTapTargetGuideline) di layar uang (M-74, M-81) sesuai docs/02.

## 5. Kualitas test

- 256 test hijau, `analyze` bersih; setiap file test punya `expect`.
- Celah: tak ada test untuk B1 (polling offline tak berhenti), B2, B3. Uji `PaymentStatusNotifier` dengan repo yang melempar `ApiException` jaringan.
- Pastikan `MockBackend` bersama tidak bocor state antar test (reset di `setUp`).

## 6. Layar docs/02 bagian 8 yang belum ada

**Tidak ada.** Seluruh M-01..06, 10..16, 20..26, 30..37, 40..45, 50..53, 60, 61, 70..77, 80..83, 90, 91, 95..97 punya `Routes.*` dan GoRoute dengan layar nyata (M-22 = bottom sheet di `shell_app_bar.dart`, sesuai docs/09). Tidak ada `PlaceholderScreen` yang terpakai.

## 7. Urutan perbaikan

1. B1, B2, B3, B5 (kecil) beserta test.
2. K1, K4, K5, K7 (hapus kode mati/duplikat; risiko rendah).
3. K2/K3 (migrasi paginasi dan mixin) sebagai refactor terpisah, commit per fitur ([[07-Git-Commit-Mobile]]).
4. B4/B6 setelah kontrak backend jelas.

## 8. Perbaikan (agent perbaikan, 2026-10-10)

Selesai: B1 (`_tick` terpisah dari `refresh`, `_polls` tak direset saat offline; berhenti di `maxPolls`), B2 (`done && mounted`), B3 (`loadMore` gagal menahan request; hanya `loadMore(retry: true)` dari tombol Coba lagi), B5 (cek `mounted` sebelum `onConflict`), B6 (`ApiException.retryAfter` dari header `Retry-After`, default 15 dtk), B7 (logout try/finally), B8 (guard `_checking`), B9 (`_Countdown` berdetak 30 dtk + live region). K1 (`ApiErrorState` dihapus, 6 layar memakai `ApiErrorView`), K4 (`stub_route.dart`, `placeholder_screen.dart` dihapus), K5 (5 key mati dihapus; `filterRate`, `otpBox(i)` pindah ke `K`), K7 (`cupertino_icons` dihapus). Keamanan: F-05, F-06, F-07 tertutup; F-09 diperiksa (selfie sudah tanpa galeri).

Test baru: `test/paging_payment_polling_test.dart` (B1, B3), M-34 keluar saat pay() berjalan (B2) di `listing_flow_screens_test.dart`.

Akar masalah test M-35: bukan bug app. Daftar "Lowongan saya" malas (ListView) dan urut createdAt menurun, sehingga lowongan seed "Pengasuh anak usia 3 tahun" (paling lama) ada di bawah viewport 900 px dan tidak terbangun; test kini menggulir (`scrollUntilVisible`).

Dilewati: B4, B10 (kontrak backend), K2, K3, K6, K8 (refactor/di luar daftar).
