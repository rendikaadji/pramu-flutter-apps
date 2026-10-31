import 'package:flutter/material.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Label tombol untuk kode aksi dari server (ajuan: SETUJUI/TOLAK/BATALKAN; pekerjaan: kebab-case).
const labelAksi = {
  'SETUJUI': 'Setujui',
  'TOLAK': 'Tolak',
  'BATALKAN': 'Batalkan',
  'TUTUP': 'Tutup job',
  'tandai-selesai': 'Tandai selesai',
  'konfirmasi-selesai': 'Konfirmasi selesai',
  'akhiri': 'Akhiri',
  'usulan-efektif': 'Usulkan hari terakhir',
  'usulan-efektif-setujui': 'Setujui usulan',
  'usulan-efektif-tolak': 'Tolak usulan',
  'batalkan': 'Batalkan pekerjaan',
  'tidak-hadir': 'Catat tidak hadir',
  'berhenti-tanpa-pemberitahuan': 'Catat berhenti tanpa pemberitahuan',
  'tidak-bisa-dilanjutkan': 'Tidak bisa dilanjutkan',
  'tidak-bisa-dilanjutkan-setujui': 'Setujui',
  'tidak-bisa-dilanjutkan-tolak': 'Tolak',
};

/// Judul dialog konfirmasi berupa pertanyaan dengan kata kerja (brief §8.3).
const tanyaAksi = {
  'SETUJUI': 'Setujui ajuan ini?',
  'TOLAK': 'Tolak ajuan ini?',
  'BATALKAN': 'Batalkan ajuan ini?',
  'TUTUP': 'Tutup job ini?',
  'tandai-selesai': 'Tandai pekerjaan selesai?',
  'konfirmasi-selesai': 'Konfirmasi pekerjaan selesai?',
  'akhiri': 'Akhiri dengan pemberitahuan?',
  'usulan-efektif': 'Usulkan hari terakhir?',
  'usulan-efektif-setujui': 'Setujui usulan hari terakhir?',
  'usulan-efektif-tolak': 'Tolak usulan hari terakhir?',
  'batalkan': 'Batalkan pekerjaan sekarang?',
  'tidak-hadir': 'Catat pihak lain tidak hadir?',
  'berhenti-tanpa-pemberitahuan': 'Catat berhenti tanpa pemberitahuan?',
  'tidak-bisa-dilanjutkan': 'Ajukan tidak bisa dilanjutkan?',
  'tidak-bisa-dilanjutkan-setujui': 'Setujui tidak bisa dilanjutkan?',
  'tidak-bisa-dilanjutkan-tolak': 'Tolak tidak bisa dilanjutkan?',
};

const _aksiBahaya = {
  'TOLAK',
  'batalkan',
  'tidak-hadir',
  'berhenti-tanpa-pemberitahuan',
};

/// Tombol untuk setiap aksi di `aksi_tersedia`. Akibat dari server ditulis sebelum tombol dan diulang di dialog
/// konfirmasi (brief v2 prinsip 3). [jalankan] mengembalikan galat (ditampilkan) atau null bila berhasil.
class DaftarAksi extends StatefulWidget {
  const DaftarAksi({
    super.key,
    required this.aksi,
    required this.jalankan,
    this.label = const {},
  });

  final Aksi aksi;
  final Future<void> Function(String kode) jalankan;

  /// Label khusus per aksi, mis. "Setujui dan bayar Rp100.000" untuk pembayar.
  final Map<String, String> label;

  @override
  State<DaftarAksi> createState() => _DaftarAksiState();
}

class _DaftarAksiState extends State<DaftarAksi> {
  String? _proses;
  String? _galat;

  Future<void> _tekan(String kode) async {
    final akibat = widget.aksi.akibat[kode];
    final ok = await ConfirmDialog.show(
      context,
      title: tanyaAksi[kode] ?? 'Lanjutkan?',
      message: akibat ?? '',
      confirmLabel: _label(kode),
      cancelLabel: 'Kembali',
      destructive: _aksiBahaya.contains(kode),
    );
    if (!ok || !mounted) return;
    setState(() {
      _proses = kode;
      _galat = null;
    });
    try {
      await widget.jalankan(kode);
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = null);
    }
  }

  String _label(String kode) => widget.label[kode] ?? labelAksi[kode] ?? kode;

  @override
  Widget build(BuildContext context) {
    final a = widget.aksi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Aksi yang belum boleh tetap tampil, nonaktif, dengan alasannya (brief §7.6).
        for (final e in a.alasanNonaktif.entries) ...[
          AppButton(label: _label(e.key), onPressed: null),
          const SizedBox(height: AppSpace.s4),
          Text(e.value, style: context.text.bodySm),
          const SizedBox(height: AppSpace.s12),
        ],
        for (final kode in a.tersedia) ...[
          if (a.akibat[kode] != null)
            Text(a.akibat[kode]!, style: context.text.bodySm),
          const SizedBox(height: AppSpace.s4),
          AppButton(
            label: _label(kode),
            variant: _aksiBahaya.contains(kode)
                ? AppButtonVariant.danger
                : kode == a.tersedia.first
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            loading: _proses == kode,
            onPressed: _proses == null ? () => _tekan(kode) : null,
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        if (_galat != null) FieldErrorText(_galat!),
      ],
    );
  }
}
