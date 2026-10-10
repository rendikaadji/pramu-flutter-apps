import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/compact_rating.dart';

int? daysLeft(Listing l, [DateTime? now]) {
  final e = l.expiresAt;
  if (e == null || l.status != ListingStatus.open) return null;
  final d = e.difference(now ?? DateTime.now().toUtc()).inDays;
  return d < 0 ? 0 : d;
}

String budgetText(Listing l) =>
    '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)} / ${l.unit.label.toLowerCase()}';

/// Kartu lowongan: judul + tarif di atas, status/penanda di tengah, footer pemilik atau pencari.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.ownerView = false,
  });

  final Listing listing;
  final VoidCallback onTap;
  final bool ownerView;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = context.tokens;
    final days = daysLeft(l);
    final chips = <Widget>[
      if (ownerView) StatusChip.of(StatusDomain.listing, wire(l.status)),
      if (!ownerView && l.applied)
        const StatusChip(label: 'Sudah dilamar', tone: StatusTone.info),
      if (l.requireSkck)
        const StatusChip(
          label: 'Wajib SKCK',
          tone: StatusTone.neutral,
          icon: LucideIcons.fileCheck,
        ),
    ];
    final footer = <Widget>[
      if (days != null) _Meta(LucideIcons.clock, 'Sisa $days hari'),
      if (ownerView) _Meta(LucideIcons.users, '${l.applicantCount} pelamar'),
      if (!ownerView) ...[
        Text(
          l.owner.name,
          style: context.text.bodySm.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (l.owner.verified)
          const VerificationSeal(size: SealSize.sm, showLabel: false),
        if (l.owner.ratingCount > 0)
          CompactRating(value: l.owner.ratingAvg, count: l.owner.ratingCount),
      ],
    ];
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.title, style: context.text.h3),
          const SizedBox(height: AppSpace.s4),
          Text(
            '${l.category} - ${l.city}',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.s12),
          MoneyText(
            '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}',
          ),
          Text(
            'per ${l.unit.label.toLowerCase()}, ${l.periodCount} periode',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s12),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: chips,
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s12),
            Divider(height: 1, color: t.borderSubtle),
            const SizedBox(height: AppSpace.s12),
            Wrap(
              spacing: AppSpace.s16,
              runSpacing: AppSpace.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: footer,
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 16, color: t.textMuted)),
        const SizedBox(width: AppSpace.s4),
        Flexible(
          child: Text(
            text,
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
        ),
      ],
    );
  }
}
