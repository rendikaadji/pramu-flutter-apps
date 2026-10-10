import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Kartu nominal "unggulan": gradien biru tua, label kecil, nominal mono besar
/// putih, dan satu baris keterangan opsional (ikon + teks + nominal kecil).
/// Teks selalu putih (kontras >= 4.5:1 di dua ujung gradien).
/// Dipakai Dompet dan Bayar periode. Nominal harus sudah terformat.
class MoneyHeroCard extends StatelessWidget {
  const MoneyHeroCard({
    super.key,
    required this.label,
    required this.amount,
    this.amountKey,
    this.footerLabel,
    this.footerAmount,
    this.footerIcon = LucideIcons.shieldCheck,
    this.semanticsLabel,
  });

  final String label;
  final String amount;

  /// Key untuk nominal utama (dibaca test).
  final Key? amountKey;
  final String? footerLabel;
  final String? footerAmount;
  final IconData footerIcon;

  /// Menggantikan pembacaan semantik default ("label, nominal").
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const white = Colors.white;
    final radius = BorderRadius.circular(AppRadius.lg);
    final text = context.text;
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.featuredFrom, t.featuredTo],
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned(
                right: -32,
                top: -32,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: white.withValues(alpha: .07),
                    ),
                    child: const SizedBox.square(dimension: 140),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -48,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: white.withValues(alpha: .05),
                    ),
                    child: const SizedBox.square(dimension: 110),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: text.label.copyWith(color: white)),
                      const SizedBox(height: AppSpace.s4),
                      KeyedSubtree(
                        key: amountKey,
                        child: Text(
                          amount,
                          style: AppText.mono(
                            size: 32,
                            lineHeight: 40,
                            weight: FontWeight.w700,
                            color: white,
                          ),
                        ),
                      ),
                      if (footerLabel != null) ...[
                        const SizedBox(height: AppSpace.s16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: white.withValues(alpha: .14),
                            borderRadius: AppRadius.brMd,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s12,
                              vertical: AppSpace.s12,
                            ),
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    footerIcon,
                                    size: 20,
                                    color: white,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.s8),
                                Expanded(
                                  child: Text(
                                    footerLabel!,
                                    style: text.bodySm.copyWith(color: white),
                                  ),
                                ),
                                if (footerAmount != null)
                                  Text(
                                    footerAmount!,
                                    style: AppText.mono(
                                      size: 14,
                                      lineHeight: 20,
                                      weight: FontWeight.w600,
                                      color: white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
