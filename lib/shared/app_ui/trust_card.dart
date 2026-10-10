import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';
import 'rating_stars.dart';
import 'verification_seal.dart';

/// Kartu kepercayaan (profil asisten, detail pelamar): segel, SKCK, rating,
/// pekerjaan selesai, bergabung sejak. Hanya data nyata; tanpa rating bila belum ada ulasan.
class TrustCard extends StatelessWidget {
  const TrustCard({
    super.key,
    this.seal = SealState.verified,
    this.skckVerified = false,
    this.rating,
    this.reviewCount = 0,
    this.completedJobs = 0,
    this.since,
    this.onSealTap,
  });

  final SealState seal;
  final bool skckVerified;
  final double? rating;
  final int reviewCount;
  final int completedJobs;

  /// Teks siap tampil, mis. "Mar 2026".
  final String? since;
  final VoidCallback? onSealTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget row(IconData? icon, Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
      child: Row(
        children: [
          if (icon != null)
            SizedBox(
              width: 28,
              child: ExcludeSemantics(
                child: Icon(icon, size: 20, color: t.textMuted),
              ),
            ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerificationSeal(state: seal, size: SealSize.lg, onTap: onSealTap),
          const SizedBox(height: AppSpace.s8),
          Divider(color: t.borderSubtle),
          const SizedBox(height: AppSpace.s8),
          if (skckVerified)
            row(
              LucideIcons.fileCheck,
              Text('SKCK terverifikasi', style: context.text.body),
            ),
          row(
            null,
            rating == null
                ? Text('Belum ada ulasan', style: context.text.body)
                : RatingStars(value: rating!, count: reviewCount),
          ),
          row(
            LucideIcons.briefcase,
            Text('$completedJobs pekerjaan selesai', style: context.text.body),
          ),
          if (since != null)
            row(
              LucideIcons.calendar,
              Text('Bergabung sejak $since', style: context.text.body),
            ),
        ],
      ),
    );
  }
}
