import 'package:flutter/material.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

class AssistantCard extends StatelessWidget {
  const AssistantCard({super.key, required this.profile, required this.onTap});
  final AssistantProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final t = context.tokens;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImage(name: p.name, url: p.photoUrl, size: 48),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: context.text.h3),
                const SizedBox(height: AppSpace.s4),
                if (p.verified)
                  const VerificationSeal(size: SealSize.sm)
                else
                  Text(
                    'Belum terverifikasi',
                    style: context.text.bodySm.copyWith(color: t.textMuted),
                  ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  [
                    if (p.categories.isNotEmpty) p.categories.join(', '),
                    if (p.city.isNotEmpty) p.city,
                  ].join(' - '),
                  style: context.text.bodySm.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: AppSpace.s8),
                if (p.ratingCount > 0)
                  RatingStars(value: p.ratingAvg, count: p.ratingCount)
                else
                  Text('Belum ada ulasan', style: context.text.bodySm),
                if (p.rate > 0) ...[
                  const SizedBox(height: AppSpace.s4),
                  Wrap(
                    spacing: AppSpace.s4,
                    children: [
                      MoneyText(formatRupiah(p.rate)),
                      Text('/ ${p.unit.label.toLowerCase()}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
