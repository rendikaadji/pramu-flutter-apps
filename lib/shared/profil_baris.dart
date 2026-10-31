import 'package:flutter/material.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Satu baris `RingkasanProfil`: nama, tanda terverifikasi/baru, rating, pekerjaan selesai, kecamatan.
class ProfilBaris extends StatelessWidget {
  const ProfilBaris({super.key, required this.profil});

  final RingkasanProfil profil;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final rincian = [
      if (profil.rating != null)
        '★ ${profil.rating!.toStringAsFixed(1)} (${profil.jumlahUlasan})',
      '${profil.jumlahSelesai} selesai',
      if (profil.kecamatan.isNotEmpty) profil.kecamatan,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarImage(name: profil.nama, url: profil.fotoUrl, size: 44),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(profil.nama, style: context.text.h3),
                  if (profil.terverifikasi)
                    _Lencana('Terverifikasi', t.successContainer),
                  if (profil.baru) _Lencana('Baru', t.primaryContainer),
                ],
              ),
              const SizedBox(height: AppSpace.s2),
              Text(rincian, style: context.text.caption),
              if (profil.badgePeringatan)
                Text(
                  'Ada catatan pembatalan',
                  style: context.text.caption.copyWith(color: t.warning),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Lencana extends StatelessWidget {
  const _Lencana(this.teks, this.warna);

  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(AppRadius.xs),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s2,
      ),
      child: Text(teks, style: context.text.caption),
    ),
  );
}
