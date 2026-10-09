---
tags: [proyek, mobile, flutter, git, commit]
status: draft
tanggal: 2026-10-09
versi: 1.0
---

# 07 — Git & Commit (Mobile)

> Branch & PR mengikuti [[Spec-Teknis-v1]] §1: `main` (rilis) ← `develop` ← `feat/*`; PR wajib direview 1 orang, CI jalankan test + lint. Repo: `asisten-mobile`. ID fitur: [[01-PRD-Mobile]]. 🟡 = verifikasi di proyek.

## 1. Format Conventional Commits

```
<type>(<scope>): <subject>

<body — opsional: APA & KENAPA, bukan bagaimana>

<footer — opsional: Refs AUTH-1, BREAKING CHANGE: ..., Co-Authored-By: ...>
```

### Type
| type | Pakai untuk | Naik versi |
|---|---|---|
| `feat` | fitur/perilaku baru bagi pengguna | minor |
| `fix` | perbaikan bug | patch |
| `refactor` | ubah struktur tanpa ubah perilaku | — |
| `perf` | percepatan/hemat memori | patch |
| `test` | tambah/ubah test saja | — |
| `docs` | dokumen | — |
| `style` | format/lint saja (tanpa logika) | — |
| `build` | Gradle, CocoaPods, pubspec, versi, signing config | — |
| `ci` | pipeline (GitHub Actions) | — |
| `chore` | rutin lain (mis. regenerate, upgrade kecil) | — |
| `revert` | membatalkan commit | — |

### Scope (satu per commit, selaras folder `features/`)
| Scope | Cakupan (ID PRD) |
|---|---|
| `auth` | AUTH-1..3, sesi, token store |
| `verification` | VER-1..3 (KTP, selfie, SKCK) |
| `profile` | PRO-1/2 |
| `listing` | LST-1..4 |
| `application` | APP-1/2 |
| `interview` | INT-1..4 |
| `chat` | CHT-1..3, Reverb |
| `booking` | BKG-1/2, agreement |
| `payment` | PAY-1..4, 7, 8, WebView Xendit, deep link bayar |
| `wallet` | PAY-5/6 (saldo, rekening, penarikan) |
| `rating` | RAT-1..3 |
| `notification` | NTF-1, FCM, daftar notifikasi |
| `report` | PRV-2/3 (laporan, dispute, share chat) |
| `ui` | komponen/tema/shared widget lintas fitur |
| `build` | konfigurasi build/signing/versi |
| `ci` | workflow |
Scope tambahan yang wajar 🟡: `core` (api client, money, env), `deps`. Bila menyentuh >1 fitur → pecah commit; kalau tak mungkin, pakai scope `core`/`ui` atau tanpa scope.

## 2. Aturan subject & body
- Subject: imperatif, huruf kecil di awal, tanpa titik, **≤ 72 karakter**. Bahasa: **Inggris atau Indonesia — pilih satu & konsisten** 🟡 (usul: Indonesia boleh, type/scope tetap English; istilah teknis English).
- Satu commit = satu perubahan logis (atomic): bisa direvert sendiri, build & test hijau di tiap commit.
- Body (wajib untuk `fix` uang/privasi, perubahan perilaku, keputusan non-obvious): kenapa, dampak, cara uji. Wrap ~72 kolom.
- Footer: `Refs: PAY-2`, `Fixes #123` (issue), `BREAKING CHANGE: ...` (kontrak API berubah).
- Perubahan kontrak API: commit ikut setelah `openapi.yaml` berubah (Rencana-Kerja §6); sebut di footer.
- Jangan campur format/lint massal dengan logika.

## 3. Contoh baik vs buruk

| Buruk | Kenapa | Baik |
|---|---|---|
| `update` | tidak informatif | `feat(listing): tambah filter kota dan rentang budget` |
| `fix bug` | tanpa konteks | `fix(payment): cegah bayar ganda dengan idempotency key per niat bayar` |
| `Fixed login.` | past tense, titik, tanpa scope | `fix(auth): hapus token lokal saat logout walau request gagal` |
| `wip` / `asdf` | tak boleh di develop | (squash/rapikan sebelum PR) |
| `feat: semua fitur chat dan bayar dan rating` | non-atomic | pecah: `feat(chat): ...`, `feat(payment): ...`, `feat(rating): ...` |
| `fix(payment): format` | menyembunyikan perubahan uang | `fix(payment): format total tagihan memakai integer rupiah dari server` |
| `chore: add google-services.json` | file terlarang (§6) | — (jangan commit) |

Contoh dengan body:
```
fix(payment): kembali dari WebView tidak lagi menandai period sebagai paid

Status paid hanya boleh dari server (webhook). Deep link return sekarang
hanya memicu refresh status period dan menampilkan layar "Memeriksa pembayaran".

Refs: PAY-2
```
```
refactor(core): satukan format rupiah ke formatRupiah(int)
test(wallet): tambah test state penarikan queued -> failed
build: naikkan versi ke 1.0.0+7
ci: jalankan flutter analyze dan test pada PR ke develop
feat(notification)!: ubah payload push menjadi type+id

BREAKING CHANGE: server harus mengirim `type` dan `id` (ULID), bukan `screen`.
```

## 4. Alur branch

```
main        ●────────────────●  (tag rilis)
             \              /
develop       ●──●──●──●──●──   (integrasi, staging)
                \   \
feat/payment-webview  feat/chat-reverb   (dari develop)
```
| Item | Aturan |
|---|---|
| Nama branch | `feat/<scope>-<singkat>`, `fix/<scope>-<singkat>`, `refactor/...`, `chore/...`, `hotfix/<singkat>` (dari `main`) |
| Merge ke `develop` | PR, 1 reviewer, CI hijau (`flutter analyze`, `flutter test`), squash atau rebase — pilih satu 🟡 (usul: **squash** → judul PR = Conventional Commit) |
| Rilis | `develop` → `main` lewat PR rilis; tag di `main`; build dari tag |
| Hotfix uang/privasi | branch dari `main` → PR ke `main` **dan** back-merge ke `develop` |
| Hindari | commit langsung ke `main`/`develop`; branch hidup >1 minggu (rebase dari `develop` rutin) |
Perubahan kontrak API: PR `openapi.yaml` dulu (repo contract/api), kabari B/C sebelum merge.

## 5. Versi & tag rilis

`pubspec.yaml`: `version: 1.0.0+12` → **nama versi** `1.0.0` (SemVer; tampil ke pengguna) + **build number** `12` (naik monoton; Android `versionCode`, iOS `CFBundleVersion`).

| Aturan | Isi |
|---|---|
| Naik versi | `feat` → minor, `fix` → patch, breaking/perubahan besar → major. Pra-rilis MVP: `0.x.y` atau `1.0.0` saat store pertama 🟡 |
| Build number | +1 tiap build yang diunggah ke Play/TestFlight (tidak boleh turun/ulang untuk versi yang sama) |
| Override di CI | `flutter build appbundle --build-name=1.0.0 --build-number=$GITHUB_RUN_NUMBER` ; `flutter build ipa --build-name=... --build-number=...` |
| Tag | `v1.0.0+12` (annotated): `git tag -a "v1.0.0+12" -m "rilis 1.0.0 build 12"` ; `git push origin "v1.0.0+12"` |
| Changelog | dari commit `feat`/`fix` sejak tag sebelumnya: `git log v1.0.0+11..v1.0.0+12 --oneline` (atau generator seperti `git-cliff` 🟡) |
| Perubahan versi | commit `build: bump versi ke 1.0.0+12` terpisah |
| Kompatibilitas API | `X-App-Version` dikirim ke server; min-version enforcement 🟡 ([[01-PRD-Mobile]] §7) |

## 6. Larangan commit

| Jangan commit | Alasan | Cara |
|---|---|---|
| Keystore: `*.jks`, `*.keystore`, `key.properties` | Kunci signing Android; hilang/bocor = tak bisa update aplikasi / bahaya | `.gitignore`; simpan di password manager/secret CI; aktifkan Play App Signing |
| `.env`, `*.env.*`, `secrets.*` | Rahasia/API key | Commit `.env.example`; `--dart-define` dari secret CI |
| Token/API key/callback token Xendit, Google OAuth | Kredensial | Hanya di server; mobile tidak butuh secret Xendit |
| `google-services.json`, `GoogleService-Info.plist` | Kebijakan tim 🟡: file ini berisi identifier proyek Firebase (bukan secret keras) namun disarankan tidak di repo publik, terutama bila ada beberapa env | Opsi A: ignore + diisi CI dari secret (base64); Opsi B: commit untuk repo **privat** bila tim sepakat. Tetapkan satu di hari 1 |
| `ios/Runner/*.p8`, `*.p12`, `*.mobileprovision`, APNs key | Sertifikat/key Apple | Keychain/fastlane match 🟡/secret CI |
| Build output: `build/`, `.dart_tool/`, `Pods/` 🟡, `*.apk`, `*.aab`, `*.ipa` | Besar & turunan | `.gitignore` bawaan `flutter create` |
| File lokal: `local.properties`, `.flutter-plugins*`, `.idea/` 🟡 | Spesifik mesin | ignore |
| Data pribadi: foto KTP/selfie asli, dump API berisi PII, log berisi token | UU PDP | fixture fiktif |
| Debug print token / base URL production | Bocor | `avoid_print` |
`pubspec.lock`: **commit** (aplikasi). Generated `*.g.dart`: putuskan sekali (commit vs ignore) 🟡.

Cek sebelum commit: `git status`, `git diff --staged`. Pencegahan: pre-commit scan rahasia (skill `implementing-secret-scanning-with-gitleaks` tersedia di Claude Code; atau `gitleaks protect --staged` 🟡). Jika terlanjur ter-commit/push: **anggap bocor → rotasi kredensial dulu**, baru bersihkan history (`git filter-repo` 🟡 — butuh koordinasi tim, force-push dikonfirmasi dulu).

## 7. Hook & validasi 🟡

Semua opsional; butuh Node untuk commitlint (Flutter repo tidak punya `package.json` default → tambahkan minimal atau pakai Lefthook yang bisa memanggil `npx`).

`commitlint.config.js`:
```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'auth','verification','profile','listing','application','interview','chat',
      'booking','payment','wallet','rating','notification','report','ui','build','ci','core','deps',
    ]],
    'subject-case': [0],
    'header-max-length': [2, 'always', 72],
  },
};
```
Pasang (npm): `npm i -D @commitlint/cli @commitlint/config-conventional`.

**Opsi A — Husky v9** 🟡:
```bash
npm i -D husky
npx husky init                  # buat .husky/ dan script prepare
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
echo 'flutter analyze' > .husky/pre-commit      # opsional, bisa lambat
```
**Opsi B — Lefthook** 🟡 (binary tunggal; `lefthook install`):
```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: npx --no -- commitlint --edit {1}
pre-commit:
  parallel: true
  commands:
    format:
      run: dart format --output=none --set-exit-if-changed {staged_files}
      glob: "*.dart"
    analyze:
      run: flutter analyze
```
Tanpa Node: validasi judul PR di CI (`amannn/action-semantic-pull-request` 🟡) + squash-merge → riwayat tetap Conventional. Jangan pakai `--no-verify` kecuali darurat yang dicatat.

## 8. Merapikan history lokal (SEBELUM push / hanya branch milik sendiri)

| Kebutuhan | Perintah |
|---|---|
| Ubah pesan commit terakhir | `git commit --amend` |
| Tambah perubahan ke commit terakhir | `git add <file> && git commit --amend --no-edit` |
| Perbaikan kecil untuk commit lama | `git commit --fixup <hash>` lalu `git rebase -i --autosquash develop` |
| Gabung/urut/ubah banyak commit | `git rebase -i develop` (pick/squash/reword/drop) — interaktif, jalankan di terminal sendiri |
| Gabung semua jadi satu | `git reset --soft $(git merge-base develop HEAD)` lalu `git commit` |
| Pecah satu commit besar | `git reset HEAD~1` → `git add -p` per bagian → commit berulang |
| Perbarui dari develop | `git fetch origin && git rebase origin/develop` |
| Batalkan commit tanpa hilangkan kerja | `git reset --soft HEAD~1` |
| Selamatkan "hilang" | `git reflog` → `git switch -c pulih <hash>` |
| Push setelah rewrite (branch pribadi) | `git push --force-with-lease` (**jangan** ke `main`/`develop`; konfirmasi tim jika branch dipakai bersama) |
Aturan: jangan rewrite history yang sudah dipakai orang lain. Sebelum rebase besar: `git branch backup/<nama>`.

## 9. Templat PR

`.github/pull_request_template.md`:
```markdown
## Ringkasan
<!-- apa & kenapa; judul PR = Conventional Commit, mis. feat(listing): ... -->

## ID fitur / tiket
Refs: LST-1, PAY-2

## Jenis
- [ ] feat  - [ ] fix  - [ ] refactor  - [ ] perf  - [ ] test  - [ ] build/ci  - [ ] docs

## Perubahan
-
-

## Uji
- [ ] `flutter analyze` bersih
- [ ] `flutter test` hijau (+ test baru untuk logika baru)
- [ ] Dicoba di: Android [ ] fisik [ ] emulator · iOS [ ] fisik [ ] simulator
- [ ] Staging (sandbox) untuk alur uang bila relevan

## Risiko uang / privasi
- [ ] Tidak menyentuh uang/privasi  ·  [ ] Menyentuh → jelaskan: …
- [ ] Tidak ada token/PII di log, fixture, screenshot
- [ ] Uang = integer rupiah; ID = ULID; error ditangani via envelope

## Kontrak API
- [ ] Tidak berubah  ·  [ ] `openapi.yaml` diperbarui (PR terkait: …)

## Checklist
- [ ] Tidak ada file terlarang (keystore, .env, google-services bila kebijakan)
- [ ] Layar baru: label semantics/Key untuk test
- [ ] Ukuran build berubah signifikan? (angka: …)

## Screenshot / rekaman (buramkan PII)
```
Review: 1 reviewer; reviewer fokus pada uang, privasi, state machine, error handling (agent `reviewer` bisa dipakai sebelum merge).

Terkait: [[06-Refactor-DeadCode-Mobile]] · [[08-Skill-Mobile]] · [[Rencana-Kerja-v1]]
