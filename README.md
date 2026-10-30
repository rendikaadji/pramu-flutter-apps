
# pramu_apps — Panduan Alur Kerja Tim (BACA INI DULU)

> **Aturan utama: sebelum menulis kode apa pun, baca dokumen yang relevan di `docs/` (lihat §2). Jangan coding sebelum paham alur.**
> README ini = pintu masuk. Detail ada di `docs/01`–`docs/08`. Bagian bertanda 🟡 = keputusan tim yang belum final.

## 1. Gambaran proyek

| Item | Isi |
|---|---|
| Nama | `pramu_apps` — app Flutter (Android + iOS), marketplace Pencari ↔ Asisten |
| Repo | `https://github.com/rendikaadji/pramu-flutter-apps.git` |
| Branch aktif | `main` (saat ini satu-satunya; lihat §6 soal `develop`) |
| SDK | Dart `^3.13.5` (lihat `pubspec.yaml`), Flutter stable yang membawa Dart tersebut |
| Lint | `flutter_lints` via `analysis_options.yaml` |
| Status kode | Baru template Flutter (`lib/main.dart` masih counter demo). Fitur belum dibangun — semua rujukan ada di PRD |
| Backend | Laravel API `/api/v1` (OpenAPI = sumber kebenaran kontrak) |

## 2. Wajib baca sebelum coding

Baca sesuai jenis tugas. **Minimal baca 01 + 07 untuk tugas apa pun.**

| Tugas kamu | Baca dulu | Kenapa |
|---|---|---|
| Fitur baru (layar/alur) | [PRD Web v1.3](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/01-PRD-Web.md) → [Brief UI/UX v2](https://github.com/rendikaadji/pramu-laravel-web/blob/main/Docs/02-UIUX-Brief-Web.md) → [02-UIUX-Brief-Mobile](docs/02-UIUX-Brief-Mobile.md) | Aturan produk, layar dan wireframe, hal khusus aplikasi. `01-PRD-Mobile` sudah usang (model lama) |
| Menyentuh login, token, uang, data pribadi | [03-Celah-Keamanan-Mobile](docs/03-Celah-Keamanan-Mobile.md) | Daftar risiko & checklist go/no-go |
| Memperbaiki bug | [04-Debug-Playbook-Mobile](docs/04-Debug-Playbook-Mobile.md) | Triage, tabel gejala → penyebab, template bug report |
| Menulis test | [05-E2E-Test-Mobile](docs/05-E2E-Test-Mobile.md) | Struktur test, test hooks (Key/Semantics), cakupan minimum |
| Refactor / bersih-bersih | [06-Refactor-DeadCode-Mobile](docs/06-Refactor-DeadCode-Mobile.md) | Prosedur aman + hal yang **tidak boleh** dihapus |
| Commit / branch / PR / rilis | [07-Git-Commit-Mobile](docs/07-Git-Commit-Mobile.md) | Format commit, scope, branch, larangan commit, template PR |
| Pakai Claude Code | [Skill pramu-mobile](docs/skills/pramu-mobile/SKILL.md) | Aturan wajib AI agent untuk model baru |
| Pilihan teknologi / stack backend | [13-Keputusan-Teknologi](docs/13-Keputusan-Teknologi.md) | Stack disetujui (Laravel, Flutter, PostgreSQL, dll.), prinsip teknis, yang belum diverifikasi |

**Checklist "sudah paham alur" (jawab sendiri sebelum mulai):**
- [ ] Saya tahu ID fitur yang saya kerjakan (mis. `LST-1`) dan AC-nya di PRD.
- [ ] Saya tahu layar/alurnya di UIUX Brief.
- [ ] Saya tahu scope commit yang dipakai (tabel scope di dokumen 07 §1).
- [ ] Saya tahu apa yang tidak boleh di-commit (dokumen 07 §6).
- [ ] Jika menyentuh uang/privasi: saya sudah baca dokumen 03.

## 3. Setup awal (sekali per mesin)

1. Pasang **Git**, **Flutter SDK** (stable), Android Studio (SDK + emulator), dan VS Code/Android Studio + plugin Flutter. iOS: butuh macOS + Xcode.
2. Atur identitas Git (sekali):
   ```bash
   git config --global user.name "Nama Kamu"
   git config --global user.email "email@kamu.com"
   ```
3. Pastikan GitHub sudah bisa diakses (HTTPS + Personal Access Token, atau SSH key) dan akunmu sudah diundang ke repo.
4. Cek lingkungan Flutter:
   ```bash
   flutter doctor
   ```
   Semua centang untuk target yang kamu pakai (Android minimal) sebelum lanjut.

## 4. Alur lengkap: dari clone sampai push branch baru

### Langkah 1 — Clone repo
```bash
git clone https://github.com/rendikaadji/pramu-flutter-apps.git pramu_apps
cd pramu_apps
```

### Langkah 2 — Baca docs (WAJIB)
Buka folder `docs/`, baca dokumen sesuai tabel §2. Pahami fitur dan ID-nya sebelum lanjut.

### Langkah 3 — Pasang dependency & cek app jalan
```bash
flutter pub get
flutter analyze
flutter test
flutter run          # pilih emulator/perangkat
```
Jika `analyze`/`test` sudah merah **sebelum** kamu mengubah apa pun, jangan lanjut — kabari tim.

### Langkah 4 — Ambil kode terbaru & buat branch baru
Selalu mulai dari branch dasar yang terbaru, **jangan kerja langsung di `main`/`develop`**.
```bash
git switch main                 # 🟡 ganti ke `develop` jika sudah dibuat (lihat §6)
git pull origin main
git switch -c feat/listing-filter-kota
```
Penamaan branch: `feat/<scope>-<singkat>`, `fix/<scope>-<singkat>`, `refactor/...`, `chore/...`, `docs/...`, `hotfix/...` (hotfix dari `main`). Huruf kecil, pakai tanda hubung.

### Langkah 5 — Coding
- Kerjakan **satu perubahan logis** per commit; jangan campur fitur baru dengan format/lint massal.
- Teks UI bahasa Indonesia; uang = integer rupiah, tampil `Rp25.000` lewat satu fungsi format; ID = ULID; waktu tampil WIB.
- Layar baru: beri `Key`/`Semantics` untuk test ([05](docs/05-E2E-Test-Mobile.md) §2).
- Jangan `print` token / data pribadi ([03](docs/03-Celah-Keamanan-Mobile.md), [04](docs/04-Debug-Playbook-Mobile.md) §4).
- Logika baru → tambahkan test di `test/`.

### Langkah 6 — Cek kualitas sebelum commit
```bash
dart format .
flutter analyze
flutter test
```
Ketiganya harus bersih. Lalu periksa isi yang akan masuk:
```bash
git status
git diff
```
Pastikan **tidak ada** file terlarang: keystore (`*.jks`, `key.properties`), `.env`, `google-services.json`, `GoogleService-Info.plist`, `build/`, foto KTP/data asli ([07](docs/07-Git-Commit-Mobile.md) §6).

### Langkah 7 — Commit (Conventional Commits)
Format: `type(scope): subject` — imperatif, huruf kecil, tanpa titik, ≤ 72 karakter.
```bash
git add lib/features/listing/ test/listing_filter_test.dart   # tambahkan file spesifik, hindari `git add .`
git commit -m "feat(listing): tambah filter kota dan rentang budget" -m "Refs: LST-2"
```
Type: `feat` `fix` `refactor` `perf` `test` `docs` `style` `build` `ci` `chore` `revert`.
Scope: `auth` `verification` `profile` `listing` `application` `interview` `chat` `booking` `rating` `notification` `report` `ui` `build` `ci` `core` `deps`.

Contoh baik / buruk:

| ❌ Buruk | ✅ Baik |
|---|---|
| `update` | `feat(listing): tambah filter kota dan rentang budget` |
| `fix bug` | `fix(auth): hapus token lokal saat logout walau request gagal` |
| `wip` | (rapikan dulu sebelum push) |

### Langkah 8 — Sinkron dengan branch dasar (jika sudah lama)
```bash
git fetch origin
git rebase origin/main        # 🟡 origin/develop bila sudah ada
```
Selesaikan konflik, lalu jalankan ulang `flutter analyze` dan `flutter test`.

### Langkah 9 — Push branch baru
Push pertama kali (set upstream):
```bash
git push -u origin feat/listing-filter-kota
```
Push berikutnya cukup `git push`. Jika kamu habis rebase di branch **pribadi**: `git push --force-with-lease` (jangan pernah force-push ke `main`/`develop`).

### Langkah 10 — Buka Pull Request
1. Buka link yang muncul di terminal, atau halaman repo → **Compare & pull request**.
2. Base: `main` (🟡 `develop` bila sudah ada). Judul PR = Conventional Commit, mis. `feat(listing): tambah filter kota dan rentang budget`.
3. Isi templat PR ([07](docs/07-Git-Commit-Mobile.md) §9): ringkasan, ID fitur, hasil uji, risiko uang/privasi, screenshot (buramkan data pribadi).
4. Minta **1 reviewer**. CI harus hijau (`flutter analyze` + `flutter test`).
5. Perbaiki komentar review dengan commit baru di branch yang sama; push lagi.
6. Setelah disetujui → **squash merge** 🟡. Hapus branch setelah merge.

### Langkah 11 — Setelah merge
```bash
git switch main
git pull origin main
git branch -d feat/listing-filter-kota
```

### Ringkasan satu layar
```bash
git clone <url> && cd pramu_apps
# baca docs/ dulu
flutter pub get && flutter analyze && flutter test
git switch main && git pull origin main
git switch -c feat/<scope>-<singkat>
# ...coding...
dart format . && flutter analyze && flutter test
git add <file> && git commit -m "feat(<scope>): <subject>"
git push -u origin feat/<scope>-<singkat>
# buka Pull Request -> review -> squash merge
```

## 5. Aturan yang tidak boleh dilanggar

1. **Tidak ada commit langsung ke `main`/`develop`.** Semua lewat PR.
2. **Jangan commit rahasia** (keystore, `.env`, token, kunci Apple/Firebase, data pribadi). Jika terlanjur: anggap bocor → **rotasi kredensial dulu**, baru bersihkan history bersama tim.
3. **Jangan `--no-verify`** atau lewati CI kecuali darurat yang dicatat.
4. **Jangan rewrite history** yang sudah dipakai orang lain.
5. **Status bayar hanya dari server** — app tidak boleh menandai lunas sendiri ([03](docs/03-Celah-Keamanan-Mobile.md)).
6. Perubahan kontrak API: PR `openapi.yaml` dulu, kabari tim backend sebelum merge.
7. Commit `pubspec.lock` (aplikasi); jangan commit `build/`, `.dart_tool/`, `*.apk/aab/ipa`.

## 6. Hal yang masih perlu diputuskan tim 🟡

| Topik | Kondisi sekarang | Usul |
|---|---|---|
| Branch `develop` | Dokumen 07 menyebut alur `main ← develop ← feat/*`, tetapi di remote **baru ada `main`** | Buat `develop` dari `main`, jadikan basis PR. Sampai itu dibuat, semua PR ke `main` |
| Nama repo | Dokumen 07 menyebut `asisten-mobile`; repo asli `pramu-flutter-apps` | Anggap nama repo asli yang berlaku |
| Merge strategy | Belum ditetapkan | Squash merge |
| Bahasa commit | Belum ditetapkan | Subject Indonesia, type/scope English |
| `google-services.json` di repo | Belum ditetapkan | Ignore, isi dari secret CI |
| Proteksi branch `main` | Belum diatur di GitHub | Aktifkan: wajib PR, 1 approval, CI hijau |
| CI (GitHub Actions) | Belum ada workflow | Tambah `flutter analyze` + `flutter test` untuk PR |

## 7. Perintah harian (cheat sheet)

| Kebutuhan | Perintah |
|---|---|
| Ambil dependency | `flutter pub get` |
| Jalankan app | `flutter run` |
| Cek lint | `flutter analyze` |
| Jalankan test | `flutter test` |
| Format kode | `dart format .` |
| Bersihkan build | `flutter clean && flutter pub get` |
| Lihat status / diff | `git status` / `git diff` |
| Lihat riwayat ringkas | `git log --oneline -15` |
| Batalkan commit terakhir (kerja tetap) | `git reset --soft HEAD~1` |
| Simpan sementara | `git stash` / `git stash pop` |
| Ganti pesan commit terakhir (belum push) | `git commit --amend` |

## 8. Butuh bantuan?

- Bug: ikuti [04-Debug-Playbook](docs/04-Debug-Playbook-Mobile.md) §1 (triage 5 menit), lalu isi template bug report.
- Ragu soal keamanan/uang: tanya sebelum coding, bukan setelah PR.
- Dokumen salah atau kurang: perbaiki lewat PR `docs(...)`, jangan simpan pengetahuan hanya di kepala sendiri.
