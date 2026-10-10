---
tags: [proyek, ui-ux, mobile, design-system]
status: draft
tanggal: 2026-10-10
versi: 2.0
---

# 10 — Design System App (Flutter)

> Kontrak untuk semua fitur. **Arah visual v2 (2026-10): terang, bersih, airy, biru langit** mengikuti referensi user; menggantikan "Buku Kas Rumah" di Brief §2-§3 (nilai token di dokumen ini yang berlaku). Sumber lain: Brief §9 (status), §10 (trust), §11 (komponen). Kode: `lib/core/theme/` dan `lib/shared/app_ui/`.

## 1. Aturan pakai (wajib)

1. **Jangan hardcode warna, ukuran font, spacing, radius, atau durasi di fitur.** Pakai `context.tokens`, `context.text`, `AppSpace`, `AppRadius`, `AppMotion`. Tidak ada `Color(0x..)`, `Colors.*`, `TextStyle(fontSize: ..)`, atau `EdgeInsets.all(13)` di `lib/features/**`.
2. **Satu import:** `import 'package:pramu_apps/shared/app_ui/app_ui.dart';` (sudah mengekspor tema, token, dan semua komponen).
3. Teks default Indonesia, microcopy dari Brief §13. Tidak ada emoji sebagai ikon; ikon hanya `LucideIcons.*` (`lucide_icons_flutter`).
4. Status = ikon + teks + warna (jangan hanya warna). Aksi penting = ikon + label. Tombol ikon = `AppIconButton` (label wajib).
5. Target sentuh >= 48dp; jangan membuat tombol sendiri dengan `GestureDetector` kecil.
6. Error kritis inline/banner/dialog, bukan snackbar. Aksi destruktif lewat `ConfirmDialog`, tidak pernah swipe.
7. Nominal selalu `MoneyText` (mono tabular). Komponen uang menerima **String sudah terformat**; format dengan `core/money` di lapisan fitur.
8. Animasi lewat `context.motion(AppMotion.base)` (menghormati reduce motion). Hanya transform/opacity.
9. Layar baru dibungkus `AppScaffold` (SafeArea, margin 16/24, lebar maks 600dp).
10. Peran: `AppRole.seeker` (Pencari, biru langit) / `AppRole.assistant` (Asisten, teal). Pemetaan dari peran domain ke `AppRole` dilakukan di fitur.

## 2. Token

Semua di `lib/core/theme/` (diekspor `app_ui.dart`).

| Kebutuhan | API |
|---|---|
| Warna (light/dark otomatis) | `context.tokens.canvas / surface / sunken / raised / borderSubtle / borderStrong / textPrimary / textMuted / textSubtle / primary / primaryContainer / onPrimary / accent / accentContainer / onAccent / success / successContainer / warning / warningContainer / danger / dangerContainer / onDanger / focusRing / scrim` |
| Warna baru (v2) | `assistant / assistantContainer` (teal), `primaryBright` (dekorasi saja), `featuredFrom/To`, `heroSoftFrom/To`, `glow`, `illoSoft / illoAccent / illoInk / illoPaper` |
| Warna per peran | `context.roleColor(role)`, `context.roleContainer(role)` |
| Elevasi | `tokens.e1` (kartu), `e2` (sheet/menu), `e3` (dialog) = `List<BoxShadow>`; kosong di dark |
| Spacing | `AppSpace.s0 s2 s4 s8 s12 s16 s20 s24 s32 s40 s48 s64`, `AppSpace.tap` (48), `AppSpace.maxContent` (600) |
| Radius | `AppRadius.xs 4 / sm 8 / md 12 / lg 20`; peran: `card 16`, `button 14`, `input 12`, `sheet 24`; `brXs brSm brMd brCard brButton brInput brLgTop` (atas 24) |
| Motion | `AppMotion.instant 100 / fast 160 / base 240 / slow 360 ms`; kurva `standard / enter / exit`; `context.motion(d)` |
| Tipografi | `context.text.display / h1 / h2 / h3 / body / bodySm / label / caption` (satu keluarga sans sistem; judul w600-700 rapat -0,3; `AppText.wordmark()` w800 untuk "Pramu") |
| Mono (uang kecil, ID, OTP) | `AppText.mono(size:, lineHeight:, weight:, color:)` atau `MoneyText` |
| Tema | `AppTheme.light()` / `AppTheme.dark()` pada `MaterialApp(theme:, darkTheme:, themeMode:)` |

Nilai kunci v2 (terang / gelap):

| Token | Terang | Gelap | Catatan |
|---|---|---|---|
| canvas / surface | `#FFFFFF` / `#FFFFFF` | `#0B1220` / `#111A2E` | netral dingin, bukan krem |
| primary | `#0770BC` (5,2:1 dgn putih) | `#5FB7F5` (teks `onPrimary #04223D`) | isian tombol/teks. Jangan `#38BDF8` mentah untuk isian bertulisan putih |
| primaryBright | `#38BDF8` | `#38BDF8` | hanya gradien, glow, ilustrasi |
| accent (oranye) | `#A8450A` | `#FDBA74` | highlight kecil, bintang, ilustrasi (`illoAccent #FB923C`) |
| assistant (teal) | `#0D6B63` | `#5EEAD4` | tint peran Asisten |
| featured gradien | `#0B2F6B`->`#0770BC` | `#0B2A5B`->`#1D6FB8` | teks putih >= 4,5:1 di dua ujung |
| success / warning / danger | `#166534` / `#92400E` / `#B91C1C` | `#4ADE80` / `#FCD34D` / `#FCA5A5` | semua AA |
| textPrimary / Muted / Subtle | `#0F172A` / `#475569` / `#536278` | `#E8EEF7` / `#A9B6C9` / `#9AA7BC` | Muted >= 7:1 |

Catatan nilai turunan (dipilih agar kontras >= 4,5:1): `onAccent`, `onDanger`. Teks di atas glow header diuji pada warna paling pekat (`HeaderGlow.peak`). Kontras dihitung di `test/shared/app_ui/contrast_test.dart` untuk kedua tema (teks, ikon, kontrol, fokus; `textMuted` >= 7:1).

`ColorScheme` dibangun manual dari token (bukan `fromSeed`): `primary`, `secondary = accent`, `error = danger`, `surface`, `surfaceContainer = sunken`. Tema komponen (tombol, input, kartu, chip, app bar, bottom nav, dialog, bottom sheet, snackbar, divider, switch/checkbox/radio, transisi halaman) sudah diatur; widget Material mentah ikut tampil benar, tetapi utamakan komponen `app_ui`.

Tombol memakai 16sp semibold (bukan `label` 14sp) demi keterbacaan pengguna literasi rendah.

## 3. Komponen

| Komponen | Contoh satu baris |
|---|---|
| `AppButton` | `AppButton(label: 'Bayar Rp1.050.000', onPressed: pay, loading: busy, large: true)`; variant `primary/secondary/tonal/danger/text`, `icon`, `expand: false`. `loading` mengunci ketukan |
| `AppIconButton` | `AppIconButton(icon: LucideIcons.bell, label: 'Notifikasi', onPressed: open)` |
| `AppTextField` | `AppTextField(label: 'Nomor KTP', obscure: true, keyboardType: TextInputType.number, maxLength: 16, errorText: err)`; `prefixText: 'Rp'`, `sensitive: true` (tanpa saran/koreksi/autofill), mask via `inputFormatters` |
| `FieldErrorText` | `FieldErrorText('Nomor KTP harus 16 digit.')` |
| `AppCard` | `AppCard(onTap: open, child: ...)` (radius 16, border tipis + e1 halus; jangan menyarang kartu) |
| `HeaderGlow` | `AppScaffold(glow: true, ...)` memasang glow biru muda lembut di atas layar (beranda, profil). AppBar transparan agar glow tampak |
| `SearchField` | `SearchField(hint: 'Cari lowongan', onTap: openSearch)` (read-only sebagai pintu) atau dengan `controller/onChanged`; `trailing:` tombol filter |
| `HeroBannerCard` | `HeroBannerCard(title:, subtitle:, ctaLabel: 'Mulai cari', onTap: go, illustration:)` gradien lembut, teks gelap |
| `FeaturedCard` | `FeaturedCard(title:, subtitle:, tags: [...], trailing: 'Rp3,5 jt / bulan', bookmarked:, onBookmark:, onTap:)` gradien tua, teks putih |
| `CategoryTile` | `CategoryTile(icon: LucideIcons.house, label: 'Kebersihan', onTap: ..., color:, iconColor:)`; taruh di `Row` + `Expanded` / `Wrap` (jangan rasio tetap) |
| `SegmentedTabs` | `SegmentedTabs(labels: ['Semua','Dilamar'], index: i, onChanged: set)` pil, menggulir horizontal |
| `ListTileCard` + `SettingsRow` | `ListTileCard(children: [SettingsRow(icon:, title:, subtitle:, onTap:, destructive:, trailing:)])` |
| `StatsRow` | `StatsRow(items: [StatItem('12', 'Selesai'), StatItem('4,8', 'Rating'), StatItem('9', 'Ulasan')])` |
| `OnboardingPager` | `OnboardingPager(pages: [OnboardingPage(illustration:, title:, body:)], onFinish: done, onSkip:)` titik indikator, Lanjut/Mulai, Lewati |
| `FilterSheet` | `FilterSheet.show(context, title: 'Filter', builder: (_) => ..., onApply: apply, onReset: reset)`; isi: chip, `RangeSlider` (sudah bertema) |
| `SuccessView` | `SuccessView(title:, message:, actionLabel:, onAction:, secondaryLabel:, illustration:)` |
| Ilustrasi | `WelcomeIllustration / SuccessIllustration / EmptyListIllustration / VerifyIllustration / MoneySafeIllustration / ChatIllustration (size: 200)`. Vektor CustomPaint, flat, dekoratif (tanpa semantics), ikut mode gelap. Tanpa aset |
| `SectionHeader` | `SectionHeader('Lowongan aktif', actionLabel: 'Lihat semua', onAction: all)` |
| `StatusChip` | `StatusChip(label: 'Dana ditahan aman', tone: StatusTone.success)` atau `StatusChip.of(StatusDomain.period, 'paid', role: AppRole.assistant)` |
| `VerificationSeal` | `VerificationSeal(state: SealState.verified, size: SealSize.md, onTap: showMeaning)`; `stamp: true` di layar status verifikasi |
| `TrustCard` | `TrustCard(skckVerified: true, rating: 4.5, reviewCount: 12, completedJobs: 8, since: 'Mar 2026')` |
| `LedgerTimeline` | `LedgerTimeline(entries: [LedgerEntry(title: 'Periode 1', label: 'Selesai', tone: StatusTone.success, date: '1 - 30 Sep', amount: 'Rp1.000.000')])` |
| `LedgerMini` | `LedgerMini(tones: [...], summary: 'Periode 2 dari 4, dana ditahan aman')` (kartu kontrak) |
| `MoneyText` | `MoneyText('Rp1.250.000', size: MoneySize.hero)` (`hero/body/small`) |
| `FeeBreakdown` | `FeeBreakdown(rows: [FeeRow('Gaji periode 1', 'Rp1.000.000'), FeeRow('Total', 'Rp1.050.000', total: true)])` |
| `NextStepCard` | `NextStepCard(title: '3 pelamar baru', message: '...', role: role, onTap: open)` |
| `RoleChip` | `RoleChip(role: role, onTap: () => showRoleSwitchSheet(context, current: role, onSelect: switchRole))` |
| `RoleSwitchSheet` | `showRoleSwitchSheet(context, current:, onSelect:, available:, onAddRole:)`; UI saja, sheet menutup dulu lalu memanggil callback |
| `AvatarImage` | `AvatarImage(name: 'Siti Rahma', url: photoUrl, size: 48)` (fallback inisial) |
| `RatingStars` | tampil `RatingStars(value: 4.5, count: 12)`; input `RatingStars(value: v, onChanged: (n) => ...)` |
| `AppBottomNav` | `AppBottomNav(role: role, index: i, onTap: go, items: [AppNavItem(icon: LucideIcons.house, label: 'Beranda')])` (4 Pencari / 5 Asisten; `badgeCount`) |
| `AppSkeleton` | `AppSkeleton.line(width: 120)`, `AppSkeleton.box(48, radius: 24)`; beri satu `Semantics(label: 'Memuat')` di pembungkus |
| `EmptyState` | `EmptyState(title: '...', message: '...', actionLabel: 'Reset filter', onAction: reset, illustration:, compact:)`; `icon` lama masih diterima tetapi tidak ditampilkan (ilustrasi dokumen default) |
| `ErrorState` | `ErrorState(message: apiMessage, code: 'SRV_500', onRetry: reload)` |
| `OfflineBanner` | `AppScaffold(banner: offline ? const OfflineBanner(updatedAt: 'diperbarui 14.02') : null, ...)` |
| `PermissionRationaleCard` | `PermissionRationaleCard(icon: LucideIcons.camera, title:, message:, primaryLabel: 'Buka Pengaturan', onPrimary: openSettings, denied: true)` |
| `ConfirmDialog` | `final ok = await ConfirmDialog.show(context, title:, message:, confirmLabel: 'Tarik lamaran', destructive: true);` |
| `AppSnack` | `AppSnack.show(context, 'Sekarang sebagai Asisten', success: true)` (info/sukses ringan saja; ikon sukses hijau) |
| `StepProgress` | `StepProgress(current: 2, total: 4, title: 'Deskripsi')` (wizard maks 4 langkah) |
| `OtpInput` | `OtpInput(onCompleted: verify, errorText: err)`; `err` baru -> goyang + getar + isian dikosongkan |
| `PrivacyNote` | `PrivacyNote('Nomor disembunyikan sampai pembayaran dilakukan, demi keamanan Anda.')` |
| `AppScaffold` | `AppScaffold(title: 'Daftar', scrollable: true, body: form)`; `bottomNavigationBar`, `floatingActionButton`, `banner`, `padded: false` |
| `DesignGalleryScreen` | `DesignGalleryScreen(initialDark: false)` di `shared/app_ui/gallery/` untuk review manual/golden. Tidak terdaftar di router; daftarkan sementara di debug bila perlu |

Belum ada (bangun di fitur bila layar membutuhkan, tetap dari token): `ListingCard`, `AssistantCard`, `ApplicantCard`, `BookingCard`, `ConversationTile`, `NotificationTile`, `MessageBubble`, `ConsentSheet`, `SecureCaptureFrame`, `DropdownField`, `ChipSelect`, `DateTimeField`, `NavigationRail` untuk >= 840dp.

## 4. Peta status

`StatusChip.of(domain, kode, role:)` memetakan kode backend (snake_case, Brief §9) ke label/tone/ikon: `StatusDomain.period | booking | application | listing | interview | verification | payout`. Kode tak dikenal tampil netral dengan kode sebagai label (terlihat saat QA). Hanya label period yang berbeda per `role`.

## 5. Font (belum terpasang)

Keputusan v2: **tanpa unduhan font dan tanpa serif**. Tema merujuk slot `IBMPlexSans` (UI + judul) dan `IBMPlexMono` (uang/ID/OTP) dengan fallback Roboto / SF Pro / Noto Sans; selama file belum ada tampil font sistem. `Fraunces` tidak dipakai lagi (abaikan di langkah di bawah bila memasang font nanti). Langkah opsional:

1. Unduh dari Google Fonts (lisensi OFL, catat di `docs/`): Fraunces (variable, atau Regular 400 + SemiBold 600), IBM Plex Sans (Regular 400, Medium 500, SemiBold 600), IBM Plex Mono (Medium 500, SemiBold 600).
2. Subset Latin (mis. `pyftsubset` / glyphhanger) agar APK kecil (Brief §16). Taruh di `assets/fonts/`.
3. Tambahkan ke `pubspec.yaml` di bawah `flutter:` (nama `family` harus persis):

```yaml
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces-SemiBold.ttf
          weight: 600
    - family: IBMPlexSans
      fonts:
        - asset: assets/fonts/IBMPlexSans-Regular.ttf
        - asset: assets/fonts/IBMPlexSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSans-SemiBold.ttf
          weight: 600
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexMono-SemiBold.ttf
          weight: 600
```

4. `flutter pub get`, lalu jalankan ulang galeri dan uji skala teks 130%/200%.

## 6. Pengujian

- `flutter test test/shared` menjalankan: kontras token (dua tema), `AppButton` (loading mengunci ketukan, tap target 48dp), `StatusChip`, `OtpInput`, `RatingStars` (semantik), dan smoke galeri 360dp (terang/gelap, skala 100/130%).
- Di test fitur gunakan helper `host()` di `test/shared/app_ui/harness.dart` sebagai contoh membungkus widget dengan `AppTheme`, dan `meetsGuideline(androidTapTargetGuideline / labeledTapTargetGuideline)` untuk layar baru.

## 7. Aturan v2 (terang, bersih, airy)

- Tombol utama lebar penuh radius 14 berisi `primary`; biru cerah/pastel hanya untuk gradien, glow, container.
- Satu bahasa kartu: putih, radius 16, border `borderSubtle`. Kartu "unggulan" (gradien tua) maksimal satu per layar.
- Ikon di kotak lembut (radius 12-16) untuk kategori/pengaturan; bottom nav ikon outline, aktif berwarna peran (Pencari biru, Asisten teal).
- Layar sukses/kosong/onboarding wajib memakai ilustrasi dari `illustrations.dart` + judul + subjudul + satu tombol.
- Lencana verifikasi = segel bergerigi biru (`VerificationSeal`), bukan lagi soga.
- Input memakai `borderStrong` (>= 3:1); `SearchField` besar memakai `borderSubtle` + bayangan karena ikon dan hint penanda utamanya.

## 8. Harness screenshot dan polish (2026-10)

- `flutter test tool/screenshots/screens_test.dart --update-goldens` menulis PNG ke `tool/screenshots/out/` (di-gitignore): 18 layar + galeri x terang/gelap/skala 1,3, 390x844. Filter: `SHOTS=home flutter test ...`. Font Segoe UI/Georgia/Consolas dari `C:\Windows\Fonts` sebagai pengganti Plex/Fraunces.
- Perubahan: radius tombol/input 12; chip filter pill; `StatusChip` pill; `AppCard` penuh lebar bila lebar terbatas dan haptic selection saat diketuk; `AppButton` secondary berborder primary 45% + haptic ringan pada primary/danger; haptic saat ganti tab; `EmptyState` ikon dalam lingkaran; segel kecil tanpa gerigi; rating 16dp tanpa ikon bintang ganda di `TrustCard`; ikon tab bawah Lucide (sebelumnya Material); Android memakai `PredictiveBackPageTransitionsBuilder`.
