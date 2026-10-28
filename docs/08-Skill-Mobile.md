---
tags: [proyek, mobile, flutter, skill, claude-code]
status: draft
tanggal: 2026-10-09
versi: 1.0
---

# 08 — Mengubah Dokumen Jadi Skill (Claude Code)

> **Perubahan lingkup 2026-10-28:** penampungan dana (escrow) dihapus: bayar periode, konfirmasi selesai, auto-release, dompet, rekening bank, tarik dana, batal+refund, potongan platform 10%, dan sengketa dana **tidak berlaku lagi** (layar M-74..76, M-80..83). Kesepakatan, kontrak (tanpa uang), biaya tayang lowongan, dan rating tetap. Acuan terbaru: [[01-PRD-Mobile]] dan [[09-Arsitektur-App]].

> Skill nyata untuk proyek ini: `Mobile\skills\asisten-mobile\SKILL.md` (sudah dibuat, **belum dipasang**). Sumber: [[PRD-v1]], [[Spec-Teknis-v1]], [[01-PRD-Mobile]], [[04-Debug-Playbook-Mobile]], [[05-E2E-Test-Mobile]], [[06-Refactor-DeadCode-Mobile]], [[07-Git-Commit-Mobile]]. 🟡 = verifikasi di versi Claude Code terpasang.

## 1. Apa itu skill

Folder berisi `SKILL.md` (frontmatter `name` + `description`, lalu instruksi Markdown). Claude Code membaca **hanya `name` + `description`** di awal (murah), dan memuat isi penuh saat tugas cocok dengan deskripsi (atau dipanggil `/nama`). Karena itu: **description = pemicu**, isi = aturan yang ringkas.

| Dokumen biasa (catatan Obsidian) | Skill |
|---|---|
| Untuk dibaca manusia, panjang, naratif | Untuk dibaca agent saat bekerja, ringkas, imperatif |
| Dimuat jika dibuka | Dimuat otomatis bila deskripsi cocok |
| Boleh duplikat penjelasan "kenapa" | Hanya "lakukan / jangan lakukan" + pointer ke detail |

## 2. Cara mengubah dokumen jadi skill (resep)

1. **Pilih satu domain sempit.** Satu skill = satu pekerjaan berulang (di sini: menulis kode app Flutter Asisten Marketplace). Jangan satu skill "semua".
2. **Ambil aturan yang selalu benar & mahal bila dilanggar** dari dokumen: uang integer, ULID, envelope error, token aman, larangan log PII, key test, role, perintah, format commit. Buang narasi, tabel risiko, jadwal, metrik.
3. **Tulis `description` dengan pemicu jelas**: *kapan* dipakai (kata kunci, jenis tugas) dan *kapan tidak*. Awali dengan apa skill ini, lalu "Pakai saat…". Hindari deskripsi umum ("membantu coding").
4. **Isi `SKILL.md` ringkas (< 200 baris, idealnya < 500 baris batas praktis)**: bentuk perintah ("Gunakan…", "Jangan…"), tabel perintah, daftar kecil. Satu hal satu kalimat.
5. **Detail panjang → file referensi**, bukan isi utama. Tunjuk lewat path; instruksikan "baca sesuai kebutuhan". (Pola progresif: metadata → SKILL.md → referensi.)
6. **Tandai ketidakpastian jujur** (mis. state management belum diputuskan) supaya agent tidak mengarang.
7. **Uji**: minta Claude tugas nyata yang memicu skill ("tambah layar bayar period"), lihat apakah (a) skill terpicu, (b) aturan dipatuhi, (c) tidak ada aturan yang bentrok dengan kode. Perketat description jika terpicu salah/tidak terpicu.
8. **Versi & rawat**: skill adalah turunan; saat Spec/PRD berubah, perbarui skill (satu tempat) — atau sebut "OpenAPI > Spec > skill" untuk prioritas.

### Anatomi
```markdown
---
name: asisten-mobile            # huruf kecil-strip; sama dengan nama folder
description: <apa> + <kapan dipakai> + <kapan jangan>
---
# Judul
## Aturan wajib …
## Perintah …
## Referensi …
```
Frontmatter lain (mis. `allowed-tools`, dll.) bersifat opsional dan bergantung versi 🟡 — jangan ditambah tanpa memverifikasi.

### Pemetaan: dokumen → bagian skill
| Sumber | Masuk skill sebagai |
|---|---|
| Spec §1 (uang integer, ULID, WIB) | §1 Uang, ID & waktu |
| Spec §2 (envelope, status, header) | §1 API client & error |
| Spec §9 + PRD §7 (privasi/log) | §1 Keamanan & privasi |
| PRD §3 / §5 (role) | §1 Pemisahan role |
| 05-E2E (key, Playwright fakta) | §1 Tes |
| 06-Refactor (target) | aturan "satu API client / satu formatter / status->aksi" |
| 07-Git (commit) | §4 Format commit |
| Semua dokumen panjang | §6 Referensi (pointer, tidak disalin) |

## 3. Skill yang sudah dibuat

Lokasi: `Mobile\skills\asisten-mobile\SKILL.md`
- `name: asisten-mobile`
- Terpicu saat: menulis/mengubah/mereview/mendebug/mengetes/refactor/commit kode di repo `asisten-mobile`, terutama uang, pembayaran, auth/token, error API, chat, push, KTP, role.
- Isi: aturan wajib (uang, ULID, envelope, token, log, key test, role), perintah standar, format commit, prioritas bug, daftar referensi.
- Tidak berisi kode proyek (belum ada); aturan akan diperbarui setelah keputusan state management (Spec §12.3) dan setelah struktur repo nyata ada.

## 4. Cara memasang (lakukan sendiri — belum dipasang)

Pilih satu:

**A. Personal (semua proyek, hanya akun Anda)** — salin folder ke `~/.claude/skills/`:
```powershell
# PowerShell (Windows)
Copy-Item -Recurse -Force `
  "C:\Users\rendi\OneDrive\Documents\Obsidian Vault\02-Proyek\Asisten-Marketplace\Mobile\skills\asisten-mobile" `
  "$env:USERPROFILE\.claude\skills\asisten-mobile"
```
**B. Per-repo (ikut tim, ikut git)** — salin ke `.claude/skills/` di root repo `asisten-mobile`:
```bash
mkdir -p .claude/skills
cp -r "<path>/Mobile/skills/asisten-mobile" .claude/skills/asisten-mobile
git add .claude/skills/asisten-mobile   # lalu commit: chore(build): tambah skill asisten-mobile
```
Rekomendasi: **B** begitu repo ada (Dev B & C memakai aturan yang sama dan versi skill ikut branch). A cocok untuk percobaan.

Catatan:
- Jalur dokumen di bagian Referensi skill memakai path vault absolut Anda. Jika skill dipasang di mesin lain/repo tim, ubah path ke lokasi dokumen di sana, atau salin dokumen yang dirujuk ke `references/` di dalam folder skill (struktur: `asisten-mobile/SKILL.md` + `asisten-mobile/references/*.md`) lalu perbarui bagian §6.
- Mulai sesi baru (atau muat ulang) agar skill terdeteksi; cek daftar skill di sesi (mis. `/skills` atau menu `/help`) 🟡 sesuai versi.
- Verifikasi: minta "buat model Period di app mobile" dan lihat apakah skill dimuat serta uang bertipe `int`.
- Skill vs CLAUDE.md: aturan yang **selalu** perlu (mis. "jalankan `flutter analyze` sebelum selesai") bisa juga di `CLAUDE.md` repo; skill lebih cocok untuk aturan domain yang hanya relevan saat mengerjakan app ini.
- Jangan memasukkan rahasia ke skill (token, key, akun demo) — ia ikut ke repo/konteks.

## 5. Skill lain yang masuk akal (opsional, belum dibuat)
| Skill | Isi | Kapan |
|---|---|---|
| `asisten-mobile-release` | Checklist rilis Play/App Store, akun demo reviewer, versi & tag | Minggu 3 |
| `asisten-mobile-payment-debug` | Triage alur Xendit WebView/deep link/webhook | Bila bug bayar sering |
Buat hanya bila ada tugas berulang nyata (hindari skill spekulatif).

Terkait: [[07-Git-Commit-Mobile]] · [[01-PRD-Mobile]]
