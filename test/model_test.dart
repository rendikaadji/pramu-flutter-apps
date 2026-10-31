import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/booking.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/features/penugasan/penugasan.dart';

// Contoh respons diambil dari bentuk Docs/openapi.yaml backend (Booking, Job, Penugasan, Akun).
const _profil = {
  'id': '01a18f68-e55e-7251-9aac-4d5dcf4e68dd',
  'nama': 'Rina W.',
  'foto_url': null,
  'terverifikasi': true,
  'rating': null,
  'jumlah_ulasan': 0,
  'jumlah_selesai': 0,
  'pembatalan_120_hari': 0,
  'badge_peringatan': false,
  'baru': true,
  'kecamatan': 'Setiabudi',
};

void main() {
  test('Akun membaca peran dan langkah onboarding', () {
    final a = Akun.fromJson({
      'id': 'x',
      'nama_depan': 'Dewi',
      'inisial': 'L.',
      'bahasa': 'id',
      'peran': ['MAJIKAN', 'PEKERJA'],
      'status_verifikasi': 'TERVERIFIKASI',
      'langkah_onboarding_berikutnya': null,
      'langkah_per_peran': {'MAJIKAN': null, 'PEKERJA': 'VIDEO'},
    });
    expect(a.peran, ['MAJIKAN', 'PEKERJA']);
    expect(a.onboardingSelesai, isTrue);
    expect(a.nama, 'Dewi L.');
    expect(a.langkahPerPeran, {'MAJIKAN': null, 'PEKERJA': 'VIDEO'});
    expect(a.langkahUntuk('PEKERJA'), 'VIDEO');
    expect(a.peranSiap, 'MAJIKAN');
  });

  test('Booking membaca aksi, akibat, alasan nonaktif, batas, dan tagihan', () {
    final b = Booking.fromJson({
      'id': 'b1',
      'aksi_tersedia': ['SETUJUI', 'TOLAK'],
      'akibat': {
        'SETUJUI': 'Setelah kalian berdua setuju…',
        'TOLAK': 'Ajuan ditolak…',
      },
      'alasan_nonaktif': <String, String>{},
      'job': {'judul': 'Bersih rumah'},
      'pihak_lain': _profil,
      'status': 'MENUNGGU_LOCK',
      'label_status': 'Menunggu persetujuan',
      'harga_kesepakatan': {'nilai': 80000, 'teks': 'Rp80.000'},
      'penanggung_biaya': null,
      'biaya_admin': {'nilai': 0, 'teks': 'Rp0'},
      'persetujuan': {'majikan_at': '2026-10-31T00:46:00Z', 'pekerja_at': null},
      'batas_lock': {
        'sampai': '2026-11-01T00:46:00Z',
        'teks': '23 jam 59 menit lagi',
      },
      'tagihan_menunggu': {
        'judul': 'Biaya admin',
        'nominal': {'nilai': 15000, 'teks': 'Rp15.000'},
      },
      'percakapan_id': 'c1',
    });
    expect(b.aksi.tersedia, ['SETUJUI', 'TOLAK']);
    expect(b.aksi.akibat['TOLAK'], 'Ajuan ditolak…');
    expect(b.majikanSetuju, isTrue);
    expect(b.pekerjaSetuju, isFalse);
    expect(b.harga.teks, 'Rp80.000');
    expect(b.batasLock!.sampai, DateTime.utc(2026, 11, 1, 0, 46));
    expect(b.tagihanTeks, 'Biaya admin: Rp15.000');
    expect(b.pihakLain.baru, isTrue);
  });

  test('alasan nonaktif dibaca walau dikirim sebagai objek kosong', () {
    final j = Job.fromJson({
      'id': 'j1',
      'judul': 'Bersih rumah',
      'status': 'TERBUKA',
      'kisaran': 'Rp60.000 – Rp110.000',
      'mulai_kerja': '2026-11-05T01:00:00Z',
      'aksi_tersedia': ['UBAH', 'TUTUP'],
      'akibat': {'TUTUP': 'Ajuan yang menunggu akan gugur.'},
      'alasan_nonaktif': <String, String>{},
      'jumlah_ajuan_menunggu': 1,
    });
    expect(j.aksi.tersedia, contains('TUTUP'));
    expect(j.aksi.alasanNonaktif, isEmpty);
    expect(j.jumlahAjuanMenunggu, 1);
  });

  test('ongkos transport dibaca dari job dan kartu, bawaan pekerja', () {
    Map<String, dynamic> job(Map<String, dynamic> tambah) => {
      'id': 'j1',
      'judul': 'ART',
      'status': 'TERBUKA',
      'mulai_kerja': '2026-11-05T01:00:00Z',
      'aksi_tersedia': <String>[],
      'akibat': <String, String>{},
      'alasan_nonaktif': <String, String>{},
      ...tambah,
    };
    expect(
      Job.fromJson(job({'ongkos_ditanggung': 'MAJIKAN'})).ongkosDitanggung,
      'MAJIKAN',
    );
    expect(Job.fromJson(job({})).ongkosDitanggung, 'PEKERJA');
    expect(kalimatOngkos('MAJIKAN'), 'Ongkos transport ditanggung majikan');
    expect(kalimatOngkos('PEKERJA'), 'Ongkos transport ditanggung pekerja');
  });

  test('booking membaca jatah gratis periodik, bawaan bukan gratis', () {
    Map<String, dynamic> dasar(Map<String, dynamic> tambah) => {
      'id': 'b1',
      'job': {'judul': 'ART'},
      'pihak_lain': {
        'id': 'p1',
        'nama': 'Siti R.',
        'terverifikasi': true,
        'jumlah_ulasan': 0,
        'jumlah_selesai': 0,
        'pembatalan_120_hari': 0,
        'badge_peringatan': false,
        'baru': true,
        'kecamatan': 'Kebayoran Baru',
      },
      'status': 'MENUNGGU_LOCK',
      'harga_kesepakatan': {'nilai': 2400000, 'teks': 'Rp2.400.000'},
      'biaya_admin': {'nilai': 0, 'teks': 'Rp0'},
      'persetujuan': {'majikan_at': null, 'pekerja_at': null},
      'batas_lock': {'sampai': '2026-11-01T00:46:00Z', 'teks': '23 jam lagi'},
      'aksi_tersedia': <String>[],
      'akibat': <String, String>{},
      'alasan_nonaktif': <String, String>{},
      ...tambah,
    };
    expect(
      Booking.fromJson(dasar({'gratis_perkenalan': true})).gratisPerkenalan,
      isTrue,
    );
    expect(Booking.fromJson(dasar({})).gratisPerkenalan, isFalse);
  });

  test('Penugasan tanpa harga dan batas tetap terbaca', () {
    final p = Penugasan.fromJson({
      'id': 'p1',
      'judul': 'ART',
      'pihak_lain': _profil,
      'label_status': 'Berjalan',
      'aksi_tersedia': ['akhiri'],
      'akibat': {'akhiri': 'Pekerjaan berakhir…'},
      'alasan_nonaktif': <String, String>{},
      'hari_ke': 3,
      'batas_konfirmasi': null,
    });
    expect(p.hariKe, 3);
    expect(p.harga, isNull);
    expect(p.batasKonfirmasi, isNull);
    expect(p.aksi.akibat['akhiri'], 'Pekerjaan berakhir…');
  });
}
