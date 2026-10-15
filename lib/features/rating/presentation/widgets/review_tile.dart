import 'package:flutter/material.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Satu ulasan: bintang + angka, nama, tanggal, komentar. `isAuto` -> label "Otomatis".
class ReviewTile extends StatelessWidget {
  const ReviewTile(this.review, {super.key, this.heading});

  final Review review;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = review.comment;
    return AppCard(
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(
                heading!,
                style: context.text.label.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
            RatingStars(value: review.stars.toDouble()),
            const SizedBox(height: AppSpace.s8),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(review.reviewerName, style: context.text.label),
                Text(
                  formatDate(review.createdAt),
                  style: context.text.caption.copyWith(color: t.textMuted),
                ),
                if (review.isAuto)
                  const StatusChip(label: 'Otomatis', tone: StatusTone.neutral),
              ],
            ),
            if (c != null && c.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s8),
              Text(c, style: context.text.body),
            ],
          ],
        ),
      ),
    );
  }
}
