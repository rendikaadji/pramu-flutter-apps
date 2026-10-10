import 'package:flutter/material.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/status_presets.dart';

AppRole appRoleOf(Role r) =>
    r == Role.seeker ? AppRole.seeker : AppRole.assistant;

/// Rincian biaya per peran. Semua angka dari server; klien hanya memformat.
List<FeeRow> contractFeeRows(Fees f, Role role) => role == Role.seeker
    ? [
        FeeRow('Total gaji kontrak', formatRupiah(f.amount)),
        FeeRow('Biaya layanan', formatRupiah(f.seekerFee)),
        FeeRow(
          'Total yang Anda bayar',
          formatRupiah(f.seekerTotal),
          total: true,
        ),
      ]
    : [
        FeeRow('Total gaji kontrak', formatRupiah(f.amount)),
        FeeRow('Biaya layanan', '-${formatRupiah(f.assistantFee)}'),
        FeeRow('Anda terima', formatRupiah(f.assistantReceives), total: true),
      ];

StatusTone periodTone(PeriodStatus s, Role role) =>
    statusPreset(StatusDomain.period, wire(s), appRoleOf(role)).tone;

String periodRange(BookingPeriod p) =>
    '${formatDate(p.start)} - ${formatDate(p.end)}';

/// Kartu kontrak di M-72.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.role,
    required this.onTap,
  });

  final Booking booking;
  final Role role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final other = role == Role.seeker ? b.assistant : b.seeker;
    final done = b.periods.where((p) => p.status.isFinal).length;
    final next = b.nextPeriod;
    final total = role == Role.seeker
        ? b.fees.seekerTotal
        : b.fees.assistantReceives;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(other.name, style: context.text.h3)),
              StatusChip.of(
                StatusDomain.booking,
                wire(b.status),
                role: appRoleOf(role),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            b.listingTitle,
            style: context.text.body.copyWith(color: context.tokens.textMuted),
          ),
          const SizedBox(height: AppSpace.s12),
          LedgerMini(
            tones: [for (final p in b.periods) periodTone(p.status, role)],
            summary: next == null
                ? '$done periode selesai'
                : 'Periode ${next.index} dari ${b.periods.length}, '
                      '${next.status.labelFor(role)}',
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              Expanded(
                child: Text(
                  next == null
                      ? 'Semua periode selesai'
                      : 'Periode ${next.index} dari ${b.periods.length}',
                  style: context.text.bodySm,
                ),
              ),
              MoneyText(formatRupiah(total)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner status penting (dijeda, sengketa, dibatalkan).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.text,
    this.danger = false,
  });
  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = danger ? t.danger : t.warning;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: danger ? t.dangerContainer : t.warningContainer,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: fg.withValues(alpha: .4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: fg)),
              const SizedBox(width: AppSpace.s12),
              Expanded(child: Text(text, style: context.text.body)),
            ],
          ),
        ),
      ),
    );
  }
}
