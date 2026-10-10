import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

int? daysLeft(Listing l, [DateTime? now]) {
  final e = l.expiresAt;
  if (e == null || l.status != ListingStatus.open) return null;
  final d = e.difference(now ?? DateTime.now().toUtc()).inDays;
  return d < 0 ? 0 : d;
}

String budgetText(Listing l) =>
    '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)} / ${l.unit.label.toLowerCase()}';

/// Kartu lowongan: tampilan pemilik (status chip + pelamar) atau asisten (pencari + lencana).
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
          const SizedBox(height: AppSpace.s8),
          Text(budgetText(l), style: context.text.body),
          Text(
            '${l.periodCount} periode ${l.unit.label.toLowerCase()}',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.s12),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ownerView)
                StatusChip.of(StatusDomain.listing, wire(l.status)),
              if (!ownerView && l.applied)
                const StatusChip(label: 'Sudah dilamar', tone: StatusTone.info),
              if (l.requireSkck)
                const StatusChip(
                  label: 'Wajib SKCK',
                  tone: StatusTone.neutral,
                  icon: LucideIcons.fileCheck,
                ),
              if (days != null)
                Text('Sisa $days hari', style: context.text.bodySm),
              if (ownerView)
                Text('${l.applicantCount} pelamar', style: context.text.bodySm),
              if (!ownerView) ...[
                if (l.owner.verified)
                  const VerificationSeal(size: SealSize.sm, showLabel: false),
                if (l.owner.ratingCount > 0)
                  RatingStars(
                    value: l.owner.ratingAvg,
                    count: l.owner.ratingCount,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
