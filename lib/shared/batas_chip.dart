import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Hitung mundur dari server (brief §10 CountdownText). Kurang dari 2 jam: warna bahaya. Teks dari server, tanpa detik.
class BatasChip extends StatelessWidget {
  const BatasChip(this.batas, {super.key, this.label});

  final BatasWaktu batas;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final segera =
        batas.sampai.difference(DateTime.now()) < const Duration(hours: 2);
    final warna = segera ? t.danger : t.warning;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: segera ? t.dangerContainer : t.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s8,
            vertical: AppSpace.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 16, color: warna),
              const SizedBox(width: AppSpace.s4),
              Flexible(
                child: Text(
                  label == null ? batas.teks : '$label: ${batas.teks}',
                  style: context.text.label.copyWith(color: warna),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris data yang belum terbuka (brief §12 LockedRow): ditampilkan terkunci, tidak disembunyikan.
class BarisTerkunci extends StatelessWidget {
  const BarisTerkunci(this.isi, {super.key});

  final String isi;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.tokens.sunken,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Row(
        children: [
          Icon(LucideIcons.lock, size: 18, color: context.tokens.textMuted),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: isi,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' · Terbuka setelah disepakati'),
                ],
              ),
              style: context.text.bodySm,
            ),
          ),
        ],
      ),
    ),
  );
}
