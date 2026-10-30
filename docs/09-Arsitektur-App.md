---
tags: [proyek, mobile, flutter, arsitektur, riverpod, go_router]
status: draft
tanggal: 2026-10-28
versi: 1.1
---

# 09 — Arsitektur App (kontrak untuk agent fitur)
> **Kode lama (29 Oktober 2026):** dokumen ini menggambarkan kode yang masih ada. Domain app akan dibangun ulang mengikuti [PRD Web v1.3](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) dan [Skema Database](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/12-Skema-Database.md) di repo pramu-laravel-web (keputusan K-47). Kontrak API berubah total dan ID berganti dari ULID ke UUIDv7.

> **v1.1 (2026-10-28):** penampungan dana (escrow) dihapus: fitur `payment` (bayar periode/konfirmasi selesai/status bayar) dan `wallet` (dompet, rekening, tarik dana) dibuang; potongan 10% (`Fees`) dibuang; periode kini `scheduled → in_progress → completed | cancelled` menurut waktu. Batal kontrak pindah ke fitur `booking` tanpa refund. Biaya tayang lowongan (Invoice/Xendit) tetap di fitur `listing`.

> Fondasi sudah jadi: `core`, lapisan **domain + data** semua fitur (mock + API), router dengan stub layar. Agent fitur hanya mengisi `presentation/` fitur masing-masing. Dokumen ini = kontrak; jika kode berbeda, kodelah yang benar, lalu perbaiki dokumen. Rujukan: [[01-PRD-Mobile]] · [[02-UIUX-Brief-Mobile]] §8–9 · [[03-Celah-Keamanan-Mobile]] · [[05-E2E-Test-Mobile]] §2 · [[06-Refactor-DeadCode-Mobile]] §5.

## 1. Stack & keputusan

Flutter 3.47 / Dart 3.13 · `flutter_riverpod` 3.x (`Notifier`/`AsyncNotifier` tulis tangan, **tanpa** codegen/freezed/build_runner) · `go_router` · `dio` · `flutter_secure_storage` · `shared_preferences` · `intl` (`id_ID`, WIB). Model = class immutable biasa; `fromJson` di entity, `toJson` di *Input. Uang `int` rupiah, ID `String` ULID, waktu UTC dari API → WIB lewat `core/time.dart`. Satu-satunya tambahan paket: `flutter_localizations` (SDK, untuk teks Material `id_ID`).

## 2. Peta folder

```
lib/
  main.dart, app.dart               # ProviderScope, MaterialApp.router (AppTheme dari core/theme)
  core/
    env.dart                        # --dart-define: USE_MOCK, API_BASE_URL, APP_VERSION, PINNED_SPKI
    providers.dart                  # prefsProvider, tokenStoreProvider, deviceIdProvider, apiClientProvider, mockBackendProvider
    api/api_client.dart             # SATU Dio (header, 401, retry GET, upload, Idempotency-Key)
    api/api_exception.dart          # error envelope (docs/06 §5.1)
    storage/secure_token_store.dart # TokenStore (Keystore/Keychain) + wipe pasca reinstall
    session/session_controller.dart # sessionProvider
    router/{app_router,routes,role_shell}.dart
    mock/{mock_backend,mock_flows}.dart  # store in-memory bersama + aturan alur lintas fitur
    models/{shared,wire}.dart       # PeriodUnit, Paged, Invoice, enum <-> snake_case
    money.dart  time.dart  ids.dart  validators.dart  test_keys.dart
    theme/  (milik desainer)        # JANGAN diubah di luar peran desainer
  shared/app_ui/ (milik desainer)
  features/<fitur>/
    domain/<f>.dart                 # entity, enum status (+ label & aksi per peran), *Input
    domain/<f>_repository.dart      # interface
    data/mock_<f>_repository.dart   # pakai MockBackend
    data/api_<f>_repository.dart    # pakai ApiClient (tipis)
    data/<f>_providers.dart         # <f>RepositoryProvider (mock/API dari Env.useMock)
    presentation/<f>_routes.dart    # List<RouteBase> <f>Routes (stub M-xx)  <- agent fitur edit
```
Fitur: `auth verification profile listing application interview chat booking rating notification report` + `home` (hanya presentasi: beranda M-20/M-21, memakai provider fitur lain).

## 3. Aturan lintas fitur

1. Fitur **tidak** mengimpor `presentation` fitur lain. Berbagi lewat `core/` atau `domain/` (+ provider `data/*_providers.dart`) fitur lain. `home` boleh membaca provider semua fitur.
2. Tak ada `Dio(`/`http` di luar `core/api/`. Token hanya di `TokenStore`. Tak ada `print` (`avoid_print` aktif); `debugPrint` tanpa token/PII/body.
3. Nominal tampil lewat `formatRupiah`, input lewat `parseRupiah`. Tidak ada potongan: anggaran, tarif lamaran, dan kesepakatan tampil apa adanya. Satu-satunya uang di app = biaya tayang lowongan (angka dari server).
4. Status → label/aksi hanya lewat extension di domain (`ApplicationStatus.allowedActions(role)`, `InterviewStatus.allowedActions(role)`, `.label`). Jangan `if (status == 'open')` di UI. Status tak dikenal → `unknown` (jangan crash).
5. Notifier yang bergantung pengguna: `ref.watch(sessionProvider.select((s) => s.user?.id))` agar state reset saat ganti akun/logout.
6. Buka URL eksternal hanya setelah `isAllowedMeetingUrl` / `isAllowedInvoiceUrl` (lalu `url_launcher`). Param deep link/return bayar biaya tayang = hanya pemicu refresh; status selalu dari API.
7. Error: tangkap `ApiException`; `status 0` = jaringan, `409` muat ulang entitas, `422` petakan `fields` ke form, `429` tombol nonaktif sementara, `403 VERIFICATION_REQUIRED` arahkan ke `Routes.verificationGate`. 401 ditangani global (jangan ditangani per layar).
8. Teks UI Indonesia; semua tombol/field kritis pakai `K.*` dari `core/test_keys.dart` (tambahkan Key baru di sana, jangan duplikat di fitur).
9. Idempotency: UI membuat `newIdempotencyKey()` **sekali per niat** (bayar biaya tayang), menyimpannya di state layar, dan memakai ulang saat retry.

## 4. Session & Router

`sessionProvider` (`SessionState {status: booting|unauthenticated|authenticated, user, expired, verificationGateSeen}`):

| Method | Fungsi |
|---|---|
| `signIn(AuthSession)` | tulis token, state authenticated (panggil setelah `verifyOtp`/`login` sukses) |
| `refreshUser()` | `me()` ulang (mis. setelah status verifikasi berubah) |
| `setRoles(Set<Role>)`, `switchRole(Role)` | AUTH-2; router otomatis memindahkan ke beranda peran baru |
| `markVerificationGateSeen()` | "Nanti dulu" di M-10 |
| `logout()` | panggil API, **lalu** hapus token + flag lokal walau gagal |
| `expire()` | dipanggil `ApiClient` pada 401 → unauthenticated, `expired=true` |
| `takeReturnTo()` | tujuan tersimpan sebelum login (router memakainya otomatis) |

Redirect (`appRedirect`, murni, teruji): booting → `/splash`; tamu hanya `Routes.publicPaths` (selain itu → `/welcome`, tujuan diingat); authenticated tanpa peran → `/onboarding/role`; path tak dikenal / param `:id` bukan ULID / query `listing|booking|draft|user|conversation` bukan ULID → beranda; `/s/*` hanya Pencari, `/a/*` hanya Asisten; akun `verification == none` yang belum menekan "Nanti dulu" diarahkan sekali ke M-10 saat membuka tab root. Allowlist deep link dibentuk dari pohon rute itu sendiri.

Navigasi: gunakan `Routes.*` (builder, mis. `context.push(Routes.bookingDetail(id))`). Tab root berada di `StatefulShellRoute.indexedStack` per peran (Pencari 5 tab, Asisten 5 tab, `role_shell.dart`). **Keputusan:** layar detail (non-tab) adalah rute penuh di navigator root (bottom nav tersembunyi) agar satu rute dipakai kedua peran; kembalikan ke dalam cabang tab hanya bila desain mewajibkan. M-22 (ganti peran) dan M-96 sebagai bottom sheet boleh dibuka dari rutenya masing-masing.

## 5. Mock vs API

`--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://.../api/v1` → semua `<f>RepositoryProvider` memakai `Api*Repository`. Default (`USE_MOCK=true`) → `Mock*Repository` di atas satu `MockBackend` in-memory (latensi 150 ms, data hilang saat app restart; token `mock.<id>` tetap valid untuk akun seed). Backend asli = repo **pramu-web** (Laravel, `routes/api.php`), yang mengikuti kontrak `Api*Repository` + `fromJson` di app ini (path `/api/v1`, `{"data":…}`, `meta.next_cursor`, snake_case, ID ULID huruf besar). Rincian server: `pramu-web/Docs/09-Arsitektur-Web.md`. Bila kontrak berubah, ubah kedua sisi dalam satu rangkaian kerja, lalu jalankan uji kontrak live:

```bash
# di pramu-web: php artisan migrate:fresh --seed && php artisan serve
flutter test test/api_contract_live_test.dart --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Uji ini dilewati di `flutter test` biasa. Data seed server sama dengan akun mock di §5.1, tetapi tanpa reaksi bot. Driver lokal server: tagihan fake lunas saat status dicek, Meet fake, OTP `123456`.

Pinning: `PINNED_SPKI` kosong = nonaktif. Bila diisi, isi `pinValidator` (api_client.dart) dengan pemeriksaan hash SPKI; tanpa validator koneksi ditolak (fail closed). Tidak ada `badCertificateCallback`.

### 5.1 Akun mock (sandi semua: `Rahasia123`)

| Nama | HP | Peran | Catatan |
|---|---|---|---|
| Bu Rina | 081234567890 | Pencari, verified | punya 5 lowongan (open, draft, awaiting_payment, 2 filled), 2 pelamar di lowongan open, 2 kontrak berjalan |
| Siti | 081298765432 | Asisten, verified, SKCK verified | lamaran ke Pak Agus (wawancara menunggu konfirmasi), kontrak dgn Bu Rina |
| Bu Maya | 081355500002 | Pencari + Asisten, verified | uji ganti peran; tanpa profil/rekening/SKCK |
| Dewi | 081355500003 | Asisten, belum verifikasi | uji gerbang verifikasi & 403 |
| Akun Ditangguhkan | 08999999999 | Pencari | login → 403 `ACCOUNT_SUSPENDED` |
| Yuni, Ani, Lestari | 081311110001/2/3 | Asisten (bot) | profil terisi, bisa dicari/diajak |
| Bu Hartini, Pak Agus | 081311110011/12 | Pencari (bot) | lowongan open (Hartini: SKCK wajib; "ART mingguan" boleh lewati wawancara) |

Pendaftaran baru: nama/HP/email bebas (duplikat → 422 `fields`).

### 5.2 Pemicu deterministik

| Skenario | Pemicu |
|---|---|
| OTP benar / salah | `123456` / selain itu (422 `OTP_INVALID`); salah ke-5 per nomor → **429** `OTP_TOO_MANY_ATTEMPTS`, OTP benar pun ditolak |
| Login salah / suspend / sesi mati | 422 `INVALID_CREDENTIALS` / 403 / 401 (token tak dikenal) |
| Review KTP | `submit` → `pending`; hasil muncul pada `current()` ke-2: NIK berakhiran `0000` → `rejected` (alasan), selain itu `verified`. SKCK `pending` → `verified` pada `skck()` berikutnya |
| Bayar biaya tayang | `pay` membuat tagihan (`https://checkout.xendit.co/web/<id>`); status `open` **hanya** setelah cek status ke-2 (`ListingRepository.get`); key idempoten sama → invoice sama |
| Periode bergerak | `scheduled` → `in_progress` → `completed` menurut `start`/`end` (jam mock `MockBackend.now`); semua final → kontrak `completed` |
| Wawancara | slot dengan **menit :45** → `confirm` pertama 502 `MEET_CREATE_FAILED`, ulang berhasil (bot tidak mengonfirmasi slot ini) |
| Kesepakatan | `approve` dgn `version` lama → 409 `AGREEMENT_VERSION_STALE`; kedua setuju → kontrak + periode dibuat, lowongan `filled` |
| Chat | kontak (HP/email) disamarkan sampai kontrak dibuat; teks `/gagal` → 503; balasan otomatis 1,5 dtk bila ada pendengar `incoming` |
| Status berubah | aksi di luar `allowedActions`/`canXxx` → 409 `*_INVALID_STATE` |
| Pelamar belum verified | `apply`/`pay`/`search` → 403 `VERIFICATION_REQUIRED`; lowongan `require_skck` tanpa SKCK → 403 `SKCK_REQUIRED` |
| Bot (pengguna `bot`) | satu langkah per pembacaan: pencari-bot shortlist → ajukan wawancara (atau terima langsung bila `skip_interview`) → nilai → terima → usul kesepakatan; asisten-bot mengonfirmasi slot & menyetujui kesepakatan. Memungkinkan alur penuh dengan 1 akun |

## 6. Kontrak provider per fitur

Semua `Provider<XRepository>` di `features/<f>/data/<f>_providers.dart`. State UI (Notifier) ditulis agent fitur di `presentation/`. Signature lengkap + doc ada di `domain/<f>_repository.dart`.

| Fitur | Provider | Method utama |
|---|---|---|
| auth | `authRepositoryProvider` | `register`, `sendOtp`, `verifyOtp`→`AuthSession`, `login`, `logout`, `me`, `setRoles`, `switchRole`, `requestPasswordReset`, `resetPassword`, `devices`, `revokeDevice`, `uploadPhoto(path)`/`removePhoto`→`AuthUser` (foto profil kedua peran, JPEG terkompres; 422 bila ditolak) |
| verification | `verificationRepositoryProvider` | `current`, `submit(ktpPath,selfiePath,nik,onProgress)`, `skck`, `uploadSkck` |
| profile | `profileRepositoryProvider` | `myProfile`, `saveProfile`, `search(AssistantFilter,cursor)`→`Paged`, `assistant(id)` |
| listing | `listingRepositoryProvider` | `browse(ListingFilter,cursor)`, `mine`, `get` (juga cek status biaya tayang), `saveDraft(ListingInput,id?)`, `pay`→`Invoice`, `close` |
| application | `applicationRepositoryProvider` | `apply`, `mine`, `forListing`, `get`, `act(id, shortlist/reject/accept/withdraw)`, `invite`, `invitations` |
| interview | `interviewRepositoryProvider` | `propose`, `get`, `byApplication`, `confirm`, `reschedule`, `cancel`, `evaluate`, `evaluation` |
| chat | `chatRepositoryProvider` | `conversations`, `messages(id,afterId)`, `send`, `markRead`, `incoming`→`Stream` (API: polling 5 dtk; Reverb menyusul) |
| booking | `bookingRepositoryProvider` | `propose`, `agreement`, `byApplication`, `approve(version)`, `counter`, `bookings`, `booking`, `cancel` |
| rating | `ratingRepositoryProvider` | `forBooking`→`BookingReviews` (`theirs` null bila belum `revealed`), `submit`, `reviewsOf` |
| notification | `notificationRepositoryProvider` | `list`, `unreadCount`, `markRead`, `markAllRead`, `registerPushToken`, `unregisterPushToken`; `notificationRoute(type,id)` memetakan payload push → rute allowlist |
| report | `reportRepositoryProvider` | `submit(ReportInput)`, `mine`, `get`, `addEvidence`, `shareConversation`, `revokeShare` |

Core: `sessionProvider`, `routerProvider`, `apiClientProvider`, `tokenStoreProvider`, `prefsProvider` (wajib di-override di `main`/test), `deviceIdProvider`, `mockBackendProvider`.

Helper: `formatRupiah/parseRupiah` (`money.dart`) · `formatDate/formatTime/formatDateTime/toWib/fromWib/parseApiTime/toApiTime` (`time.dart`, panggil `initLocale()` di main/test) · `validatePhone/Email/Password/Nik/Required`, `normalizePhone`, `isUlid`, `isAllowedMeetingUrl/InvoiceUrl` (`validators.dart`) · `newIdempotencyKey/ulid/uuidV4` (`ids.dart`) · `PeriodUnit`, `Paged`, `Invoice` (`models/shared.dart`).

## 7. Stub rute per fitur

Ganti hanya `builder` stub di `features/<f>/presentation/<f>_routes.dart` (path dari `Routes`, jangan diubah; param `:id` = ULID). Tab root ditandai ★ (router memasangnya ke cabang shell).

| Fitur | Layar (ID → path) |
|---|---|
| auth | M-01 `/welcome` · M-02 `/register` · M-03 `/otp` · M-04 `/onboarding/role` · M-05 `/login` · M-06 `/forgot` · M-24 `/account`, ★`/s/profile` (tab Profil Pencari), ★`/a/profile` (tab Profil Pelamar) · M-26 `/account/devices` (M-22 = bottom sheet, tanpa rute) |
| verification | M-10 `/verification` · M-11 `/verification/guide` · M-12 `/verification/ktp` · M-13 `/verification/selfie` · M-14 `/verification/review` · M-15 `/verification/status` · M-16 `/skck` (`?listing=<ulid>`) |
| home | M-20 ★`/s/home` · M-21 ★`/a/home` |
| notification | M-23 `/notifications` |
| profile | M-30 ★`/s/search` · M-31 `/assistants/:id` · M-40 `/profile/edit` |
| listing | M-33 `/listings/new` (`?draft=<ulid>`) · M-34 `/listings/:id/pay` · M-35 ★`/s/jobs` · M-36 `/listings/:id/manage` · M-41 ★`/a/listings` · M-42 `/listings/:id` |
| application | M-32 `/assistants/:id/invite` · M-37 `/applications/:id/applicant` · M-43 `/listings/:id/apply` · M-44 ★`/a/jobs` · M-45 `/applications/:id` |
| interview | M-50 `/applications/:id/interview/propose` · M-51 `/interviews/:id/confirm` · M-52 `/interviews/:id` · M-53 `/interviews/:id/evaluation` |
| chat | M-60 ★`/s/chat` & ★`/a/chat` · M-61 `/chat/:id` |
| booking | M-70 `/applications/:id/agreement/new` · M-71 `/agreements/:id` · M-72 `/contracts` · M-73 `/bookings/:id` · M-77 `/bookings/:id/cancel` · `/pay/return?listing=<ulid>` (redirect ke M-34) |
| rating | M-90 `/bookings/:id/rating` · M-91 `/users/:id/reviews` |
| report | M-25 `/account/privacy` · M-95 `/report/new` (`?booking=&user=&conversation=`; `user` = terlapor, wire `reported_user_id`) · M-96 `/reports/:id/share` · M-97 `/reports/:id` |

Catatan: nomor HP/PII tidak boleh di path/query (mis. M-03 membaca nomor dari state fitur auth, bukan URL). Deep link push: `notificationRoute(type, ulid)`. Return Xendit biaya tayang: App Link `https://<APP_LINK_HOST>/pay/return?listing=<ulid>`.

## 8. Platform (sudah diterapkan)

Android: `allowBackup=false`, `dataExtractionRules` + `fullBackupContent` (res/xml) mengecualikan semua domain, `usesCleartextTraffic=false`, hanya `MainActivity` exported (periksa manifest hasil merge saat plugin native bertambah), `minSdk 26`, label "Pramu". iOS: `CFBundleDisplayName` "Pramu", `NSCameraUsageDescription` & `NSPhotoLibraryUsageDescription` spesifik. `applicationId`/bundle id **masih `com.example.pramu_apps`** — ganti sebelum rilis. Orientasi portrait only (main.dart).

## 9. Perintah

```bash
dart format lib test && flutter analyze && flutter test
flutter run --dart-define=USE_MOCK=true          # default
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://staging.example/api/v1
# emulator Android ke pramu-web lokal (php artisan serve --host=0.0.0.0): API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Android memblokir HTTP polos di build release/profile (`usesCleartextTraffic=false`). Khusus build **debug** diizinkan lewat `android/app/src/debug/AndroidManifest.xml`, sehingga emulator bisa memakai server lokal:

```bash
# pramu-web: php artisan migrate:fresh --seed && php artisan serve --host=0.0.0.0 --port=8000
flutter run -d emulator-5554 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Perangkat fisik di jaringan yang sama: ganti `10.0.2.2` dengan IP LAN komputer (firewall harus mengizinkan port 8000). Login uji: `081234567890` / `Rahasia123`.

Dokumen terkait: [[06-Refactor-DeadCode-Mobile]] · [[05-E2E-Test-Mobile]] · [[07-Git-Commit-Mobile]]

## Kontrak nominal

Tidak ada fee atau potongan platform. Anggaran lowongan, `proposed_rate`, tarif profil, tarif kesepakatan, dan nominal periode dikirim dan ditampilkan apa adanya untuk semua peran. Biaya tayang lowongan (Rp25.000) terpisah dan tampil di layar bayar.
