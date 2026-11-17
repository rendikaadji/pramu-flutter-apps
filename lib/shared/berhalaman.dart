import 'package:flutter/material.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Daftar berhalaman: halaman pertama dari provider, halaman berikutnya dimuat lewat tombol "Muat lagi".
/// [isi] menerima semua baris yang sudah dimuat dan tombolnya (null bila tidak ada halaman lagi), agar layar menaruhnya
/// di tempat yang pas (di atas untuk chat yang terbalik).
///
/// Saat halaman pertama dimuat ulang (tarik untuk menyegarkan, pemeriksaan berkala), halaman lanjutan yang sudah dimuat
/// dibuang, kecuali [kunci] diberikan: baris lanjutan dipertahankan dan baris yang kini ada di halaman pertama tidak
/// digandakan.
class Berhalaman<T> extends StatefulWidget {
  const Berhalaman({
    super.key,
    required this.awal,
    required this.isi,
    this.kunci,
  });

  final Paged<T> awal;
  final Widget Function(List<T> baris, Widget? muatLagi) isi;
  final Object? Function(T)? kunci;

  @override
  State<Berhalaman<T>> createState() => _BerhalamanState<T>();
}

class _BerhalamanState<T> extends State<Berhalaman<T>> {
  final _lanjutan = <T>[];
  Future<Paged<T>> Function()? _berikutnya;
  bool _sudahLanjut = false;
  bool _proses = false;
  String? _galat;

  @override
  void didUpdateWidget(covariant Berhalaman<T> lama) {
    super.didUpdateWidget(lama);
    if (!identical(lama.awal, widget.awal) && widget.kunci == null) {
      _lanjutan.clear();
      _berikutnya = null;
      _sudahLanjut = false;
    }
  }

  Future<Paged<T>> Function()? get _sesudahnya =>
      _sudahLanjut ? _berikutnya : widget.awal.berikutnya;

  Future<void> _muat() async {
    final ambil = _sesudahnya;
    if (ambil == null) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final h = await ambil();
      if (!mounted) return;
      setState(() {
        _lanjutan.addAll(h.items);
        _berikutnya = h.berikutnya;
        _sudahLanjut = true;
      });
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kunci = widget.kunci;
    final diAwal = kunci == null
        ? const <Object?>{}
        : {for (final b in widget.awal.items) kunci(b)};
    final baris = [
      ...widget.awal.items,
      for (final b in _lanjutan)
        if (kunci == null || !diAwal.contains(kunci(b))) b,
    ];
    final ada = _sesudahnya != null;
    final muatLagi = !ada
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_galat != null) FieldErrorText(_galat!),
                AppButton(
                  label: 'Muat lagi',
                  variant: AppButtonVariant.secondary,
                  loading: _proses,
                  onPressed: _proses ? null : _muat,
                ),
              ],
            ),
          );
    return widget.isi(baris, muatLagi);
  }
}
