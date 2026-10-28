import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'money_text.dart';
import 'status_chip.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.label,
    required this.tone,
    required this.date,
    this.title,
    this.amount,
    this.icon,
  });

  /// Teks status (chip), mis. "Sedang berjalan".
  final String label;
  final StatusTone tone;

  /// Teks tanggal siap tampil, mis. "9 Okt 2026".
  final String date;

  /// Nama baris, mis. "Periode 1".
  final String? title;

  /// Nominal siap tampil, mis. "Rp1.050.000".
  final String? amount;
  final IconData? icon;
}

/// Garis ledger: kolom penanda bertinta + garis tegak ganda ala buku kas, baris
/// berpetak (garis tipis antar-baris). Dipakai untuk period di detail kontrak.
class LedgerTimeline extends StatelessWidget {
  const LedgerTimeline({super.key, required this.entries});

  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _Row(entries[i], first: i == 0, last: i == entries.length - 1, t: t),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
    this.e, {
    required this.first,
    required this.last,
    required this.t,
  });
  final LedgerEntry e;
  final bool first, last;
  final AppTokens t;

  @override
  Widget build(BuildContext context) {
    final fg = e.tone.fg(t);
    final rule = BorderSide(color: t.borderSubtle);
    return Semantics(
      container: true,
      label: [
        if (e.title != null) e.title!,
        e.label,
        e.date,
        if (e.amount != null) e.amount!,
      ].join(', '),
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: first ? null : t.borderStrong,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: e.tone.bg(t),
                      borderRadius: AppRadius.brXs,
                      border: Border.all(color: fg, width: 1.5),
                    ),
                    child: Icon(e.icon ?? e.tone.icon, size: 14, color: fg),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: last ? null : t.borderStrong,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: last ? BorderSide.none : rule),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.title != null)
                              Text(e.title!, style: context.text.h3),
                            const SizedBox(height: AppSpace.s4),
                            StatusChip(
                              label: e.label,
                              tone: e.tone,
                              icon: e.icon,
                            ),
                            const SizedBox(height: AppSpace.s4),
                            Text(e.date, style: context.text.bodySm),
                          ],
                        ),
                      ),
                      if (e.amount != null) ...[
                        const SizedBox(width: AppSpace.s8),
                        MoneyText(e.amount!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versi mini untuk kartu kontrak: deretan kotak status tersambung.
class LedgerMini extends StatelessWidget {
  const LedgerMini({super.key, required this.tones, this.summary});

  final List<StatusTone> tones;

  /// Dibacakan screen reader, mis. "Periode 2 dari 4, sedang berjalan".
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: summary ?? '${tones.length} periode',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < tones.length; i++) ...[
            if (i > 0)
              Expanded(child: Container(height: 2, color: t.borderStrong)),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: tones[i].bg(t),
                borderRadius: AppRadius.brXs,
                border: Border.all(color: tones[i].fg(t), width: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
