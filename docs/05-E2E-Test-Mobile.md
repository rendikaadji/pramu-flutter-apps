---
tags: [proyek, mobile, flutter, e2e, testing, playwright]
status: draft
tanggal: 2026-10-09
versi: 1.0
---

# 05 — E2E Test Mobile

> Spec uji: [[Spec-Teknis-v1]] §10 ("integration test login→lamar→bayar (sandbox); uji di Android & iOS fisik"). Fitur: [[01-PRD-Mobile]]. **Belum ada kode** → semua snippet adalah templat; ganti nama paket/key/endpoint dengan yang nyata. 🟡 = verifikasi versi/API paket saat dipasang.

## 1. Fakta penting (jujur)

**Playwright TIDAK bisa menggerakkan app Flutter native (Android APK / iOS IPA).** Playwright mengendalikan browser (Chromium/Firefox/WebKit) — bukan emulator/perangkat, bukan UI native. Karena itu:

| Tujuan | Alat yang benar |
|---|---|
| Menggerakkan UI app Flutter native | `integration_test` (bawaan SDK), Patrol 🟡, Maestro 🟡, (Appium + Flutter driver 🟡, tidak direkomendasikan) |
| Smoke UI jika ada build **Flutter Web** | Playwright (terbatas, §4) |
| Alur backend yang dipakai mobile (API) | Playwright `APIRequestContext` (§5) — E2E **API**, bukan UI |
| Layar/komponen tunggal | `flutter test` (widget test) + golden |

Piramida disarankan: banyak unit/widget test → beberapa `integration_test` (alur kritis) → E2E API di CI backend → uji manual perangkat fisik (checklist §9).

## 2. Struktur & kesiapan app (test hooks)

```
asisten-mobile/
  test/                      # unit + widget + golden
  integration_test/
    app_test.dart            # alur login→lamar
    pay_sandbox_test.dart    # alur bayar sandbox
    helpers/api.dart         # seed + simulasi webhook (staging)
  patrol_test/               # opsional (Patrol) 🟡
  .maestro/                  # opsional (Maestro) 🟡
e2e-api/                     # Playwright APIRequestContext (bisa di repo api atau contract)
```

**Key / semantics label** (dibuat konsisten, satu file `test_keys.dart`):

```dart
// lib/core/test_keys.dart
import 'package:flutter/widgets.dart';

abstract final class K {
  static const loginPhone = Key('login_phone');
  static const loginPassword = Key('login_password');
  static const loginSubmit = Key('login_submit');
  static const otpInput = Key('otp_input');
  static const tabSearchJobs = Key('tab_search_jobs');
  static Key listingCard(String ulid) => Key('listing_$ulid');
  static const applySubmit = Key('apply_submit');
  static const applyMessage = Key('apply_message');
  static const payButton = Key('pay_button');
  static const paymentChecking = Key('payment_checking');
  static const periodStatus = Key('period_status');
}
```

Aturan: setiap tombol aksi/field/input kritis punya `Key`; untuk Maestro/aksesibilitas tambahkan `Semantics(identifier: 'login_submit', label: 'Masuk', ...)` 🟡 (properti `identifier` ada di Flutter versi baru — verifikasi di SDK terpasang). Jangan memakai teks UI sebagai finder utama (berubah saat copywriting).

## 3. (a) Utama — `integration_test` Flutter

Setup `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test: { sdk: flutter }
  integration_test: { sdk: flutter }
```
Jalankan:
```bash
flutter test integration_test/app_test.dart -d <deviceId>          # emulator/perangkat
flutter test integration_test --dart-define=API_BASE=https://api.staging.<domain>/api/v1 \
  --dart-define=E2E_PHONE=08xxxxxxxxxx --dart-define=E2E_PASS=...  # JANGAN commit nilai nyata
```
Pisahkan environment lewat `--dart-define` (tidak hardcode URL/akun).

### 3.1 Contoh: login → cari lowongan → lamar
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:asisten_mobile/main.dart' as app;     // placeholder nama paket
import 'package:asisten_mobile/core/test_keys.dart';

const phone = String.fromEnvironment('E2E_ASISTEN_PHONE');
const pass = String.fromEnvironment('E2E_PASS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('asisten login lalu melamar lowongan', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.enterText(find.byKey(K.loginPhone), phone);
    await tester.enterText(find.byKey(K.loginPassword), pass);
    await tester.tap(find.byKey(K.loginSubmit));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byKey(K.tabSearchJobs), findsOneWidget);

    // lowongan seed yang pasti ada di staging (lihat §7)
    const seededListing = '01HZZZZZZZZZZZZZZZZZZZZZZZ'; // placeholder ULID
    await tester.scrollUntilVisible(find.byKey(K.listingCard(seededListing)), 300);
    await tester.tap(find.byKey(K.listingCard(seededListing)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.applyMessage), 'Saya berpengalaman 3 tahun');
    await tester.tap(find.byKey(K.applySubmit));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Sudah dilamar'), findsOneWidget); // copy final dari UIUX
  });
}
```
Tips: pakai `tester.pumpAndSettle` hanya bila tidak ada animasi tak berhenti (spinner, shimmer) — jika ada, pakai helper `pumpUntilFound(finder, timeout)`:

```dart
Future<void> pumpUntilFound(WidgetTester t, Finder f, {Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 250));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Tidak ditemukan: $f');
}
```

### 3.2 Contoh: alur bayar sandbox
Keterbatasan: halaman Xendit di **WebView/browser** tidak bisa digerakkan `integration_test` (platform view/native). Strategi yang valid:
1. App memanggil `POST /booking-periods/{id}/pay` → dapat `invoice_url` → WebView terbuka (assert WebView/layar "Memeriksa pembayaran" muncul).
2. Test **tidak** mengisi halaman Xendit; ia memanggil **simulasi pembayaran sandbox** di sisi backend (helper API, §5.3) dengan webhook ber-token callback valid ke staging.
3. App kembali (tutup WebView lewat tombol/ deep link yang ditiru) → poll status → assert `paid`.
(Alternatif: uji klik di halaman Xendit pakai Patrol native automation 🟡 — rapuh, hanya manual/nightly.)

```dart
// integration_test/pay_sandbox_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asisten_mobile/main.dart' as app;
import 'package:asisten_mobile/core/test_keys.dart';
import 'helpers/api.dart'; // login via API, seed booking, simulatePaidWebhook

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pencari bayar period (sandbox) -> status paid', (tester) async {
    final seed = await E2eApi().seedBookingAwaitingPayment(); // {periodUlid, externalId, amount}
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await loginAsSeeker(tester);                                // helper UI login
    await openBookingPeriod(tester, seed.periodUlid);

    await tester.tap(find.byKey(K.payButton));
    await pumpUntilFound(tester, find.byKey(K.paymentChecking)); // layar cek status setelah WebView

    await E2eApi().simulatePaidWebhook(seed.externalId, seed.amount); // webhook ke staging

    await pumpUntilFound(tester, find.text('Dibayar'));          // label status "paid" final dari UIUX
    expect(find.byKey(K.periodStatus), findsOneWidget);
  });
}
```
Catatan: `helpers/api.dart` memakai `package:http`/`dio` ke staging; kredensial dari `--dart-define`. Jangan memanggil sandbox/webhook pada production.

### 3.3 Alternatif 🟡 (verifikasi sebelum adopsi)

| Alat | Kelebihan | Kekurangan | Catatan |
|---|---|---|---|
| **Patrol** (`patrol`, `patrol_cli`) | Bisa menyentuh UI native (dialog izin kamera/notifikasi, notification shade, WebView terbatas) di atas `integration_test` | Setup native tambahan (Android instrumentation, iOS RunnerUITests) | `dart pub global activate patrol_cli`; `patrol test`; `$.native.grantPermissionWhenInUse()` |
| **Maestro** | YAML sederhana, tidak perlu ubah kode app; bagus smoke/flow manual→otomatis | Mengandalkan accessibility/semantics; Flutter perlu `Semantics` label/identifier; iOS hanya simulator di cloud-free | `maestro test .maestro/login.yaml` |
Rekomendasi: mulai **integration_test** saja (nol dependency tambahan), tambah Patrol bila dialog izin native menghambat.

Contoh Maestro 🟡:
```yaml
# .maestro/login_apply.yaml
appId: id.asisten.app           # placeholder applicationId
---
- launchApp:
    clearState: true
- tapOn: "Masuk"
- tapOn:
    id: "login_phone"
- inputText: "08xxxxxxxxxx"
- tapOn:
    id: "login_password"
- inputText: ${E2E_PASS}         # maestro test -e E2E_PASS=... 
- tapOn:
    id: "login_submit"
- assertVisible: "Cari kerja"
```

## 4. (b1) Playwright untuk Flutter Web 🟡 (hanya jika ada build web)

Syarat: Flutter Web **bukan target rilis** (Android+iOS); gunakan hanya untuk smoke layar non-native (login, daftar lowongan, form). Kamera, FCM, secure storage, WebView berbeda di web → di luar cakupan.

Build & serve:
```bash
flutter build web          # output build/web
npx http-server build/web -p 8080   # atau python -m http.server 8080 -d build/web
```
Flutter Web me-render ke canvas; agar Playwright dapat menemukan elemen, aktifkan **semantics** (tombol tersembunyi `flt-semantic-placeholder`) atau panggil `SemanticsBinding.instance.ensureSemantics()` di build uji 🟡.

```ts
// web-smoke/login.spec.ts
import { test, expect } from '@playwright/test';

test('flutter web: halaman login tampil dan validasi kosong', async ({ page }) => {
  await page.goto('http://localhost:8080');
  // aktifkan accessibility tree Flutter
  await page.locator('flt-semantic-placeholder').click({ force: true });
  await expect(page.getByRole('button', { name: 'Masuk' })).toBeVisible();
  await page.getByRole('button', { name: 'Masuk' }).click();
  await expect(page.getByText('Nomor HP wajib diisi')).toBeVisible(); // copy placeholder
});
```
Jika semantics tidak terpasang, Playwright hanya bisa klik koordinat — rapuh; **jangan** dipakai.

## 5. (b2) Playwright `APIRequestContext` — E2E alur backend yang dikonsumsi mobile

Ini menguji kontrak [[Spec-Teknis-v1]] §3 tanpa UI: daftar → verifikasi → lowongan → lamar → kesepakatan → bayar sandbox → settlement. Berjalan di staging (Xendit sandbox). Berguna sebagai gerbang minggu 1–3 (Rencana-Kerja) dan regresi kontrak ketika `openapi.yaml` berubah.

Setup:
```bash
npm i -D @playwright/test
# playwright.config.ts
```
```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e-api',
  timeout: 120_000,
  workers: 1,                     // alur berurutan & berbagi data staging
  use: {
    baseURL: process.env.API_BASE ?? 'https://api.staging.example/api/v1', // placeholder
    extraHTTPHeaders: { Accept: 'application/json', 'Accept-Language': 'id', 'X-App-Version': 'e2e' },
  },
});
```

### 5.1 Helper
```ts
// e2e-api/helpers.ts
import { APIRequestContext, expect } from '@playwright/test';

export const rupiah = (n: number) => { expect(Number.isInteger(n)).toBeTruthy(); return n; }; // uang = integer

export async function login(req: APIRequestContext, phone: string, password: string) {
  const r = await req.post('auth/login', { data: { phone, password } });
  expect(r.ok()).toBeTruthy();
  const { data } = await r.json();                 // envelope sukses: { data }
  return { Authorization: `Bearer ${data.token}`, 'X-Device-Id': 'e2e-device' }; // nama field token 🟡 cek OpenAPI
}

export async function expectError(r: import('@playwright/test').APIResponse, status: number, code: string) {
  expect(r.status()).toBe(status);
  const body = await r.json();
  expect(body.error.code).toBe(code);              // envelope error Spec §2
}
```

### 5.2 Alur penuh
```ts
// e2e-api/full-flow.spec.ts
import { test, expect } from '@playwright/test';
import { login, rupiah, expectError } from './helpers';
import { randomUUID } from 'crypto';

test.describe.serial('alur penuh: lowongan -> bayar -> settlement', () => {
  let seeker: Record<string, string>, assistant: Record<string, string>;
  let listingId: string, applicationId: string, agreementId: string, bookingId: string, periodId: string;

  test.beforeAll(async ({ playwright }) => {
    const req = await playwright.request.newContext();
    // akun seed staging yang SUDAH verified (lihat §7); registrasi+OTP lewat test helper staging 🟡
    seeker = await login(req, process.env.E2E_SEEKER_PHONE!, process.env.E2E_PASS!);
    assistant = await login(req, process.env.E2E_ASSIST_PHONE!, process.env.E2E_PASS!);
  });

  test('pencari buat lowongan + bayar fee (sandbox webhook) -> open', async ({ request }) => {
    const c = await request.post('listings', { headers: seeker, data: {
      category_id: process.env.E2E_CATEGORY_ID, title: 'ART harian', description: 'x', city_id: process.env.E2E_CITY_ID,
      period_type: 'monthly', period_count: 1, start_date: '2026-11-01', budget_min: 2_000_000, budget_max: 3_000_000,
      require_skck: false, screening_questions: [] } });
    expect(c.status()).toBe(201);
    listingId = (await c.json()).data.id;                       // ULID
    const pay = await request.post(`listings/${listingId}/pay`, { headers: { ...seeker, 'Idempotency-Key': randomUUID() } });
    expect(pay.ok()).toBeTruthy();
    // simulasi webhook invoice (lihat §5.3) lalu cek status
    // await simulateXenditInvoicePaid(request, externalId, 25_000);
    const g = await request.get(`listings/${listingId}`, { headers: seeker });
    expect((await g.json()).data.status).toBe('open');
  });

  test('asisten melamar; lamar ganda -> 409', async ({ request }) => {
    const a = await request.post(`listings/${listingId}/applications`, { headers: assistant, data: { message: 'siap', proposed_rate: rupiah(2_500_000), answers: [] } });
    expect(a.status()).toBe(201);
    applicationId = (await a.json()).data.id;
    const dup = await request.post(`listings/${listingId}/applications`, { headers: assistant, data: { message: 'lagi', proposed_rate: 2_500_000, answers: [] } });
    expect([409, 422]).toContain(dup.status());                 // kode pasti ikut OpenAPI 🟡
  });

  test('shortlist -> accept -> kesepakatan dua arah -> booking', async ({ request }) => {
    expect((await request.post(`applications/${applicationId}/shortlist`, { headers: seeker })).ok()).toBeTruthy();
    expect((await request.post(`applications/${applicationId}/accept`, { headers: seeker })).ok()).toBeTruthy();
    const ag = await request.post(`applications/${applicationId}/agreement`, { headers: seeker, data: {
      rate_per_period: 2_500_000, period_type: 'monthly', period_count: 1, billing_cycle: 'monthly', start_date: '2026-11-01' } });
    agreementId = (await ag.json()).data.id;
    // approve hanya satu pihak -> booking belum ada
    expect((await request.post(`agreements/${agreementId}/approve`, { headers: assistant })).ok()).toBeTruthy();
    expect((await request.get('bookings', { headers: seeker })).ok()).toBeTruthy();
    // pengusul menyetujui juga (endpoint persis ikut OpenAPI 🟡)
    const ap = await request.post(`agreements/${agreementId}/approve`, { headers: seeker });
    expect(ap.ok()).toBeTruthy();
    const b = await (await request.get('bookings', { headers: seeker })).json();
    bookingId = b.data[0].id;
    periodId = (await (await request.get(`bookings/${bookingId}`, { headers: seeker })).json()).data.periods[0].id;
  });

  test('fee 10% (5%+5%) benar & uang integer', async ({ request }) => {
    const pay = await request.post(`booking-periods/${periodId}/pay`, { headers: { ...seeker, 'Idempotency-Key': randomUUID() } });
    const d = (await pay.json()).data;
    expect(rupiah(d.amount)).toBe(2_500_000);
    expect(rupiah(d.total)).toBe(2_500_000 + 125_000);          // A + fee pencari 5% (nama field 🟡)
  });
  // lanjut: simulate webhook paid -> period 'paid' -> (staging) majukan waktu / panggil job -> settled -> wallet naik A-fa
});
```

### 5.3 Simulasi webhook Xendit (staging/sandbox saja)
Backend memverifikasi header callback token (Spec §8: `/webhooks/xendit/invoice`, idempotent via `webhook_events.event_id`). Header token Xendit = `x-callback-token` 🟡 (verifikasi di dokumentasi Xendit & implementasi backend). Bentuk payload mengikuti Invoice callback Xendit (`id`, `external_id`, `status: "PAID"`, `amount`, `paid_amount`, ...) 🟡 — **verifikasi payload terbaru**.

```ts
// e2e-api/xendit.ts
import { APIRequestContext, expect } from '@playwright/test';

export async function simulateXenditInvoicePaid(
  req: APIRequestContext, externalId: string, amount: number, eventId = `evt-${externalId}`) {
  const send = () => req.post('webhooks/xendit/invoice', {
    headers: { 'x-callback-token': process.env.XENDIT_CALLBACK_TOKEN! },   // token STAGING, dari secret CI
    data: { id: eventId, external_id: externalId, status: 'PAID', amount, paid_amount: amount },
  });
  const r1 = await send();
  expect(r1.ok()).toBeTruthy();
  const r2 = await send();                       // duplikat: harus idempotent
  expect(r2.ok()).toBeTruthy();
}

export async function webhookRejectsBadToken(req: APIRequestContext) {
  const r = await req.post('webhooks/xendit/invoice', { headers: { 'x-callback-token': 'salah' }, data: {} });
  expect([401, 403]).toContain(r.status());
}
```
Asersi tambahan: setelah dua kali kirim, ledger tidak ganda (cek lewat `/wallet`/endpoint admin test 🟡), dan period `paid` tepat sekali.

Catatan waktu: auto-release 24 jam & scheduler 15 menit tidak bisa ditunggu → butuh **hook uji di staging** (mis. artisan command / endpoint test-only yang dilindungi, atau memajukan jam) — minta Dev A 🟡. Jangan aktifkan di production.

### 5.4 Negatif wajib
- Pencari tanpa `verified` → 403 saat posting; asisten akses `/listings/{id}/applications` milik orang lain → 403/404 (IDOR); admin token ke chat → 403 (tanggung jawab backend, tapi cek kontrak).
- Tanpa `Idempotency-Key` pada endpoint uang → ditolak/diperlakukan sesuai spec 🟡.

## 6. Matriks perangkat 🟡

| Tier | Android | iOS | Dipakai untuk |
|---|---|---|---|
| Minimum | Android 8/9 (API 26/28), RAM 2–3 GB, layar kecil 5" | iPhone dgn iOS 14 (mis. iPhone 8/SE 2) | Performa, layout sempit, kompatibilitas |
| Umum | Android 12–13 (Samsung/Xiaomi/Oppo) | iOS 16–17 | UAT utama, push, kamera, WebView bayar |
| Terbaru | Android 14/15 | iOS 18/terbaru | Izin baru (POST_NOTIFICATIONS, photo picker), edge-to-edge |
Minimal 1 perangkat **fisik** per OS untuk: kamera KTP, push (iOS wajib fisik), deep link, WebView bayar. Emulator/simulator untuk CI cepat. Vendor Android agresif baterai (Xiaomi/Oppo/Vivo) untuk uji push background.

## 7. Data uji & akun demo

| Data | Aturan |
|---|---|
| Akun seed staging | Pencari `verified`, Asisten `verified`, Pencari `unverified`, akun dgn 2 role; **dibuat oleh seeder backend** (minta Dev A), bukan registrasi manual tiap run |
| OTP | Staging: kode tetap/log-driver untuk nomor uji 🟡 (jangan di production) |
| Rahasia | `E2E_*`, `XENDIT_CALLBACK_TOKEN` hanya di GitHub Secrets / `--dart-define`, **tidak di repo** |
| Lowongan seed | 1 listing `open` dengan ULID tetap, 1 listing `require_skck` |
| Sandbox Xendit | Kartu/VA uji dari dokumentasi Xendit 🟡 |
| Reset | Seeder idempoten / endpoint reset khusus staging; setiap tes buat data unik (ULID/UUID suffix) |
| Akun reviewer store | Sama dengan akun demo ([[01-PRD-Mobile]] §9) — jangan pakai ulang untuk tes destruktif |
| Privasi | Data uji = data fiktif; foto KTP uji = gambar contoh, bukan KTP asli |

## 8. CI 🟡

GitHub Actions (Spec §12.4: CI = GitHub Actions 🟡). Pisahkan job:

```yaml
# .github/workflows/mobile-ci.yml  (templat)
name: mobile-ci
on: { pull_request: { branches: [develop, main] } }
jobs:
  static-and-unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2        # 🟡 cek versi action terbaru
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
  integration-android:
    runs-on: ubuntu-latest                       # emulator butuh KVM; pakai reactivecircus/android-emulator-runner 🟡
    needs: static-and-unit
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          script: flutter test integration_test --dart-define=API_BASE=${{ secrets.STAGING_API }} --dart-define=E2E_PASS=${{ secrets.E2E_PASS }}
  api-e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci && npx playwright test
        env: { API_BASE: ${{ secrets.STAGING_API }}, XENDIT_CALLBACK_TOKEN: ${{ secrets.XENDIT_CB }} }
```
- iOS: runner `macos-latest` (lebih mahal), simulator via `xcrun simctl`; jalankan nightly, bukan tiap PR.
- **Firebase Test Lab** 🟡: Android — bangun app + test (`flutter build apk --debug` + `./gradlew app:assembleAndroidTest`, `./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart`), lalu `gcloud firebase test android run --type instrumentation --app ... --test ...`; iOS — `flutter build ios --release --config-only` + `xcodebuild build-for-testing` → zip → `gcloud firebase test ios run`. Ikuti panduan resmi Flutter "Integration testing → Firebase Test Lab" (prosedur berubah antarversi). Berguna untuk matriks perangkat fisik.
- Artefak: unggah laporan Playwright, log, screenshot kegagalan.

## 9. Screenshot, golden, a11y

| Teknik | Cara |
|---|---|
| Golden (widget) | `await expectLater(find.byType(ListingCard), matchesGoldenFile('goldens/listing_card.png'));` update: `flutter test --update-goldens`. Golden bergantung platform/font → generate di CI (Linux) agar stabil; set font test eksplisit. Hanya untuk komponen stabil (kartu, badge status, rincian harga) |
| Screenshot integration | `binding.takeScreenshot('nama')` (Android perlu `convertFlutterSurfaceToImage()` 🟡) |
| Semantics | `expect(tester, meetsGuideline(androidTapTargetGuideline));` `labeledTapTargetGuideline`, `textContrastGuideline` (bawaan flutter_test) |
| Text scale | uji `MediaQuery(textScaler: TextScaler.linear(1.3))` pada layar form |
| Checklist manual perangkat fisik | kamera KTP (cahaya redup), izin ditolak lalu diizinkan lewat Pengaturan, push 3 status, deep link bayar, jaringan putus saat upload, rotasi, kill app saat bayar |

## 10. Penanganan flaky

1. Tunggu kondisi, bukan waktu: `pumpUntilFound` / `expect` + `waitFor`; hindari `Future.delayed` tetap.
2. Data unik per run; tes independen (jangan bergantung urutan) — kecuali alur API serial yang memang berurutan.
3. Matikan animasi tak berujung di build uji (flag `E2E` via `--dart-define`), stub spinner.
4. Network: staging stabil; tambahkan retry hanya untuk GET dan hanya di level CI (`retries: 1` Playwright; ulangi job integration 1x). Retry yang menutupi bug uang = dilarang.
5. Karantina: tes flaky diberi tag/skip + issue; batas 2 minggu.
6. Simpan log + screenshot saat gagal; ulang di perangkat fisik sebelum menyebut "flaky".
7. Pisahkan tes yang butuh internet pihak ketiga (Xendit hosted page) dari PR gate → nightly.

## 11. Cakupan minimum (selaras Spec §10 & Rencana-Kerja)

| Alur | Lapisan | Gerbang |
|---|---|---|
| Daftar → OTP → login | integration_test | Minggu 1 |
| Upload KTP → status verified | integration (seed admin approve) + API | Minggu 1 |
| Login → cari → lamar | integration_test | Minggu 2 |
| Lowongan → bayar fee → open | API E2E + integration | Minggu 2 |
| Sepakat → booking | API E2E | Minggu 2 |
| Bayar period sandbox → paid → settlement → wallet | API E2E + integration (webhook disimulasi) | Minggu 3 (go/no-go) |
| Webhook ganda & token salah | API E2E | Minggu 3 |
| Push (3 status) & deep link | manual perangkat fisik | Minggu 3 UAT |

Terkait: [[04-Debug-Playbook-Mobile]] · [[06-Refactor-DeadCode-Mobile]] · [[07-Git-Commit-Mobile]] · [[PRD-v1]]
