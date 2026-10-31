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

const _aksiBahaya = {
  'TOLAK',
  'batalkan',
  'tidak-hadir',
  'berhenti-tanpa-pemberitahuan',
};

/// Tombol untuk setiap aksi di `aksi_tersedia`. Akibat dari server ditulis sebelum tombol dan diulang di dialog
/// konfirmasi (brief v2 prinsip 3). [jalankan] mengembalikan galat (ditampilkan) atau null bila berhasil.
class DaftarAksi extends StatefulWidget {
  const DaftarAksi({super.key, required this.aksi, required this.jalankan});

  final Aksi aksi;
  final Future<void> Function(String kode) jalankan;

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
      title: labelAksi[kode] ?? kode,
      message: akibat ?? 'Lanjutkan?',
      confirmLabel: labelAksi[kode] ?? 'Lanjutkan',
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

  @override
  Widget build(BuildContext context) {
    final a = widget.aksi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pesan in a.alasanNonaktif.values) ...[
          Text(pesan, style: context.text.bodySm),
          const SizedBox(height: AppSpace.s8),
        ],
        for (final kode in a.tersedia) ...[
          if (a.akibat[kode] != null)
            Text(a.akibat[kode]!, style: context.text.bodySm),
          const SizedBox(height: AppSpace.s4),
          AppButton(
            label: labelAksi[kode] ?? kode,
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
