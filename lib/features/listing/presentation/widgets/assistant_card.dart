import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/compact_rating.dart';
import 'package:pramu_apps/shared/app_ui/icon_info_row.dart';
import 'package:pramu_apps/shared/app_ui/rate_text.dart';

/// Kartu asisten di hasil cari: identitas + kepercayaan di atas, rating dan tarif di footer.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarImage(name: p.name, url: p.photoUrl, size: 56),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: context.text.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.s4),
                    if (p.verified)
                      const VerificationSeal(size: SealSize.sm)
                    else
                      Text(
                        'Belum terverifikasi',
                        style: context.text.bodySm.copyWith(color: t.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (p.categories.isNotEmpty || p.city.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s12),
            if (p.categories.isNotEmpty)
              IconInfoRow(
                icon: LucideIcons.briefcase,
                text: p.categories.join(', '),
                small: true,
              ),
            if (p.categories.isNotEmpty && p.city.isNotEmpty)
              const SizedBox(height: AppSpace.s4),
            if (p.city.isNotEmpty)
              IconInfoRow(icon: LucideIcons.mapPin, text: p.city, small: true),
          ],
          const SizedBox(height: AppSpace.s12),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: AppSpace.s12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.s12,
              runSpacing: AppSpace.s8,
              children: [
                if (p.ratingCount > 0)
                  CompactRating(value: p.ratingAvg, count: p.ratingCount)
                else
                  Text(
                    'Belum ada ulasan',
                    style: context.text.bodySm.copyWith(color: t.textMuted),
                  ),
                if (p.rate > 0)
                  RateText(
                    formatRupiah(p.rate),
                    unit: p.unit.label.toLowerCase(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
