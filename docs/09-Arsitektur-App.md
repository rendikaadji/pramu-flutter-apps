---
tags: [proyek, mobile, flutter, arsitektur, riverpod, go_router]
status: draft
tanggal: 2026-10-10
versi: 1.0
---

# 09 — Arsitektur App (kontrak untuk agent fitur)

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
Fitur: `auth verification profile listing application interview chat booking payment wallet rating notification report` + `home` (hanya presentasi: beranda M-20/M-21, memakai provider fitur lain).

## 3. Aturan lintas fitur

1. Fitur **tidak** mengimpor `presentation` fitur lain. Berbagi lewat `core/` atau `domain/` (+ provider `data/*_providers.dart`) fitur lain. `home` boleh membaca provider semua fitur.
2. Tak ada `Dio(`/`http` di luar `core/api/`. Token hanya di `TokenStore`. Tak ada `print` (`avoid_print` aktif); `debugPrint` tanpa token/PII/body.
3. Uang tampil lewat `formatRupiah`, input lewat `parseRupiah`; **jangan hitung fee untuk dikirim** (hanya tampilkan `Fees`/`BookingPeriod.total` dari repo). Model fee: 10% dipotong dari sisi Pelamar; server mengirim nominal bersih (90%) ke Pelamar dan nominal asli ke Pencari, UI tidak menampilkan baris "Biaya layanan".
4. Status → label/aksi hanya lewat extension di domain (`PeriodStatus.actionsFor(role)`, `ApplicationStatus.allowedActions(role)`, `InterviewStatus.allowedActions(role)`, `.label`). Jangan `if (status == 'paid')` di UI. Status tak dikenal → `unknown` (jangan crash).
5. Notifier yang bergantung pengguna: `ref.watch(sessionProvider.select((s) => s.user?.id))` agar state reset saat ganti akun/logout.
6. Buka URL eksternal hanya setelah `isAllowedMeetingUrl` / `isAllowedInvoiceUrl` (lalu `url_launcher`). Param deep link/return bayar = hanya pemicu refresh; status selalu dari API.
7. Error: tangkap `ApiException`; `status 0` = jaringan, `409` muat ulang entitas, `422` petakan `fields` ke form, `429` tombol nonaktif sementara, `403 VERIFICATION_REQUIRED` arahkan ke `Routes.verificationGate`. 401 ditangani global (jangan ditangani per layar).
8. Teks UI Indonesia; semua tombol/field kritis pakai `K.*` dari `core/test_keys.dart` (tambahkan Key baru di sana, jangan duplikat di fitur).
9. Idempotency: UI membuat `newIdempotencyKey()` **sekali per niat** (bayar period, tarik dana), menyimpannya di state layar, dan memakai ulang saat retry.

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

Redirect (`appRedirect`, murni, teruji): booting → `/splash`; tamu hanya `Routes.publicPaths` (selain itu → `/welcome`, tujuan diingat); authenticated tanpa peran → `/onboarding/role`; path tak dikenal / param `:id` bukan ULID / query `listing|booking|period|draft` bukan ULID → beranda; `/s/*` hanya Pencari, `/a/*` hanya Asisten; akun `verification == none` yang belum menekan "Nanti dulu" diarahkan sekali ke M-10 saat membuka tab root. Allowlist deep link dibentuk dari pohon rute itu sendiri.

Navigasi: gunakan `Routes.*` (builder, mis. `context.push(Routes.bookingDetail(id))`). Tab root berada di `StatefulShellRoute.indexedStack` per peran (Pencari 5 tab, Asisten 5 tab, `role_shell.dart`). **Keputusan:** layar detail (non-tab) adalah rute penuh di navigator root (bottom nav tersembunyi) agar satu rute dipakai kedua peran; kembalikan ke dalam cabang tab hanya bila desain mewajibkan. M-72 = `/contracts` (segmen "Kontrak" di dalam tab Pekerjaan boleh menautkan ke sini). M-22 (ganti peran) dan M-96 sebagai bottom sheet boleh dibuka dari rutenya masing-masing.

## 5. Mock vs API

`--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://.../api/v1` → semua `<f>RepositoryProvider` memakai `Api*Repository`. Default (`USE_MOCK=true`) → `Mock*Repository` di atas satu `MockBackend` in-memory (latensi 150 ms, data hilang saat app restart; token `mock.<id>` tetap valid untuk akun seed). Bentuk API (path `/api/v1`, `{"data":…}`, `meta.next_cursor`, field snake_case) adalah **asumsi** sampai `openapi.yaml` ada; sesuaikan di `Api*Repository` + `fromJson` saja.

Pinning: `PINNED_SPKI` kosong = nonaktif. Bila diisi, isi `pinValidator` (api_client.dart) dengan pemeriksaan hash SPKI; tanpa validator koneksi ditolak (fail closed). Tidak ada `badCertificateCallback`.

### 5.1 Akun mock (sandi semua: `Rahasia123`)

| Nama | HP | Peran | Catatan |
|---|---|---|---|
| Bu Rina | 081234567890 | Pencari, verified | punya 5 lowongan (open, draft, awaiting_payment, 2 filled), 2 pelamar di lowongan open, 2 kontrak (1 aktif, 1 `paused`) |
| Siti | 081298765432 | Asisten, verified, SKCK verified | lamaran ke Pak Agus (wawancara menunggu konfirmasi), kontrak dgn Bu Rina (periode 1 selesai), dompet Rp1.425.000, rekening BCA |
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
| Bayar fee lowongan / period | `pay`/`startPayment` membuat tagihan (`https://checkout.xendit.co/web/<id>`); status `open`/`paid` **hanya** setelah cek status ke-2 (`ListingRepository.get` / `PaymentRepository.checkStatus`) |
| Idempotency | `startPayment` dgn key sama → invoice sama; `requestPayout` key sama → transaksi sama |
| Period bergerak | `paid` → `in_progress` (+15 dtk) → `awaiting_confirmation` (+30 dtk, `autoReleaseAt` +24 jam) lewat `booking()/period()`; `MockBackend.stepDelay` dapat diubah. Tagihan lewat `dueAt` → booking `paused` (seed Bu Rina–Ani) |
| Wawancara | slot dengan **menit :45** → `confirm` pertama 502 `MEET_CREATE_FAILED`, ulang berhasil (bot tidak mengonfirmasi slot ini) |
| Kesepakatan | `approve` dgn `version` lama → 409 `AGREEMENT_VERSION_STALE`; kedua setuju → booking + period dibuat, lowongan `filled` |
| Chat | kontak (HP/email) disamarkan sampai ada period dibayar; teks `/gagal` → 503; balasan otomatis 1,5 dtk bila ada pendengar `incoming` |
| Dompet | tarik min Rp10.000 & ≤ saldo (422), tanpa rekening 409 `BANK_ACCOUNT_REQUIRED`; `queued`→`processing`→`success`; nominal **99.999** → `failed` (saldo kembali) |
| Status berubah | aksi di luar `allowedActions`/`canXxx` → 409 `*_INVALID_STATE` |
| Pelamar belum verified | `apply`/`pay`/`search` → 403 `VERIFICATION_REQUIRED`; lowongan `require_skck` tanpa SKCK → 403 `SKCK_REQUIRED` |
| Bot (pengguna `bot`) | satu langkah per pembacaan: pencari-bot shortlist → ajukan wawancara (atau terima langsung bila `skip_interview`) → nilai → terima → usul kesepakatan; asisten-bot mengonfirmasi slot & menyetujui kesepakatan. Memungkinkan alur penuh dengan 1 akun |

## 6. Kontrak provider per fitur

Semua `Provider<XRepository>` di `features/<f>/data/<f>_providers.dart`. State UI (Notifier) ditulis agent fitur di `presentation/`. Signature lengkap + doc ada di `domain/<f>_repository.dart`.

| Fitur | Provider | Method utama |
|---|---|---|
| auth | `authRepositoryProvider` | `register`, `sendOtp`, `verifyOtp`→`AuthSession`, `login`, `logout`, `me`, `setRoles`, `switchRole`, `requestPasswordReset`, `resetPassword`, `devices`, `revokeDevice` |
| verification | `verificationRepositoryProvider` | `current`, `submit(ktpPath,selfiePath,nik,onProgress)`, `skck`, `uploadSkck` |
| profile | `profileRepositoryProvider` | `myProfile`, `saveProfile`, `search(AssistantFilter,cursor)`→`Paged`, `assistant(id)` |
| listing | `listingRepositoryProvider` | `browse(ListingFilter,cursor)`, `mine`, `get` (juga cek status bayar), `saveDraft(ListingInput,id?)`, `pay`→`Invoice`, `close` |
| application | `applicationRepositoryProvider` | `apply`, `mine`, `forListing`, `get`, `act(id, shortlist/reject/accept/withdraw)`, `invite`, `invitations` |
| interview | `interviewRepositoryProvider` | `propose`, `get`, `byApplication`, `confirm`, `reschedule`, `cancel`, `evaluate`, `evaluation` |
| chat | `chatRepositoryProvider` | `conversations`, `messages(id,afterId)`, `send`, `markRead`, `incoming`→`Stream` (API: polling 5 dtk; Reverb menyusul) |
| booking | `bookingRepositoryProvider` | `previewFees`, `propose`, `agreement`, `byApplication`, `approve(version)`, `counter`, `bookings`, `booking`, `period` |
| payment | `paymentRepositoryProvider` | `startPayment(periodId,idempotencyKey)`→`Invoice`, `checkStatus`, `confirmComplete`, `cancelPreview`, `cancel` |
| wallet | `walletRepositoryProvider` | `wallet`, `transactions`, `bankAccount`, `saveBankAccount`, `requestPayout(amount,idempotencyKey)` |
| rating | `ratingRepositoryProvider` | `forBooking`→`BookingReviews` (`theirs` null bila belum `revealed`), `submit`, `reviewsOf` |
| notification | `notificationRepositoryProvider` | `list`, `unreadCount`, `markRead`, `markAllRead`, `registerPushToken`, `unregisterPushToken`; `notificationRoute(type,id)` memetakan payload push → rute allowlist |
| report | `reportRepositoryProvider` | `submit(ReportInput)`, `mine`, `get`, `addEvidence`, `shareConversation`, `revokeShare` |

Core: `sessionProvider`, `routerProvider`, `apiClientProvider`, `tokenStoreProvider`, `prefsProvider` (wajib di-override di `main`/test), `deviceIdProvider`, `mockBackendProvider`.

Helper: `formatRupiah/parseRupiah` (`money.dart`) · `formatDate/formatTime/formatDateTime/toWib/fromWib/parseApiTime/toApiTime` (`time.dart`, panggil `initLocale()` di main/test) · `validatePhone/Email/Password/Nik/Required`, `normalizePhone`, `isUlid`, `isAllowedMeetingUrl/InvoiceUrl` (`validators.dart`) · `newIdempotencyKey/ulid/uuidV4` (`ids.dart`) · `PeriodUnit`, `Paged`, `Invoice` (`models/shared.dart`).

## 7. Stub rute per fitur

Ganti hanya `builder` stub di `features/<f>/presentation/<f>_routes.dart` (path dari `Routes`, jangan diubah; param `:id` = ULID). Tab root ditandai ★ (router memasangnya ke cabang shell).

| Fitur | Layar (ID → path) |
|---|---|
| auth | M-01 `/welcome` · M-02 `/register` · M-03 `/otp` · M-04 `/onboarding/role` · M-05 `/login` · M-06 `/forgot` · M-24 `/account` · M-26 `/account/devices` (M-22 = bottom sheet, tanpa rute) |
| verification | M-10 `/verification` · M-11 `/verification/guide` · M-12 `/verification/ktp` · M-13 `/verification/selfie` · M-14 `/verification/review` · M-15 `/verification/status` · M-16 `/skck` (`?listing=<ulid>`) |
| home | M-20 ★`/s/home` · M-21 ★`/a/home` |
| notification | M-23 `/notifications` |
| profile | M-30 ★`/s/search` · M-31 `/assistants/:id` · M-40 `/profile/edit` |
| listing | M-33 `/listings/new` (`?draft=<ulid>`) · M-34 `/listings/:id/pay` · M-35 ★`/s/jobs` · M-36 `/listings/:id/manage` · M-41 ★`/a/listings` · M-42 `/listings/:id` |
| application | M-32 `/assistants/:id/invite` · M-37 `/applications/:id/applicant` · M-43 `/listings/:id/apply` · M-44 ★`/a/jobs` · M-45 `/applications/:id` |
| interview | M-50 `/applications/:id/interview/propose` · M-51 `/interviews/:id/confirm` · M-52 `/interviews/:id` · M-53 `/interviews/:id/evaluation` |
| chat | M-60 ★`/s/chat` & ★`/a/chat` · M-61 `/chat/:id` |
| booking | M-70 `/applications/:id/agreement/new` · M-71 `/agreements/:id` · M-72 `/contracts` · M-73 `/bookings/:id` |
| payment | M-74 `/periods/:id/pay` · M-75 `/periods/:id/status` · M-76 `/periods/:id/confirm` · M-77 `/bookings/:id/cancel` · `/pay/return?period=<ulid>` (redirect ke M-75, sudah jadi) |
| wallet | M-80 ★`/a/wallet` · M-81 `/wallet/payout` · M-82 `/wallet/bank` · M-83 `/wallet/history` |
| rating | M-90 `/bookings/:id/rating` · M-91 `/users/:id/reviews` |
| report | M-25 `/account/privacy` · M-95 `/report/new` (`?booking=&period=`) · M-96 `/reports/:id/share` · M-97 `/reports/:id` |

Catatan: nomor HP/PII tidak boleh di path/query (mis. M-03 membaca nomor dari state fitur auth, bukan URL). Deep link push: `notificationRoute(type, ulid)`. Return Xendit: `asisten://pay/return?period=<ulid>` (scheme/App Links dikonfigurasi saat integrasi native; MOB-SEC-02).

## 8. Platform (sudah diterapkan)

Android: `allowBackup=false`, `dataExtractionRules` + `fullBackupContent` (res/xml) mengecualikan semua domain, `usesCleartextTraffic=false`, hanya `MainActivity` exported (periksa manifest hasil merge saat plugin native bertambah), `minSdk 26`, label "Pramu". iOS: `CFBundleDisplayName` "Pramu", `NSCameraUsageDescription` & `NSPhotoLibraryUsageDescription` spesifik. `applicationId`/bundle id **masih `com.example.pramu_apps`** — ganti sebelum rilis. Orientasi portrait only (main.dart).

## 9. Perintah

```bash
dart format lib test && flutter analyze && flutter test
flutter run --dart-define=USE_MOCK=true          # default
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://staging.example/api/v1
```

Dokumen terkait: [[06-Refactor-DeadCode-Mobile]] · [[05-E2E-Test-Mobile]] · [[07-Git-Commit-Mobile]]

## Kontrak fee untuk backend (diterapkan di mock, wajib diikuti server)

- Potongan platform 10% seluruhnya di sisi asisten. Pencari membayar tepat nominal yang diinput (`seeker_fee = 0`, `seeker_total = amount`); asisten menerima `amount - 10%`.
- Respons per peran: untuk pemanggil berperan asisten, semua nominal yang berasal dari pencari (budget lowongan, `proposed_rate`, `rate`/`fees` kesepakatan, `rate`/`fees`/`amount` booking & periode) dikirim **sudah bersih (90%)**, `assistant_fee = 0`. Untuk pencari dikirim nominal asli.
- Input asisten (tarif lamaran, tawaran balik kesepakatan) adalah nominal bersih; server mengonversi ke nominal pencari (dibulatkan ke atas: `ceil(net * 100 / 90)`).
- Klien tidak menampilkan baris biaya layanan di mana pun; `Fees`/`BookingPeriod` hanya diformat.
- Biaya pasang lowongan (Rp25.000) terpisah dan tetap ditampilkan.
