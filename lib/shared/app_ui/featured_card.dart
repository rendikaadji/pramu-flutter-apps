import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Kartu "unggulan": gradien biru tua, teks putih, tag, ikon bookmark.
/// Teks selalu putih (kedua ujung gradien >= 4.5:1 dengan putih di dua tema).
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.title,
    this.subtitle,
    this.tags = const [],
    this.trailing,
    this.leadingIcon = LucideIcons.briefcase,
    this.bookmarked = false,
    this.onBookmark,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final List<String> tags;

  /// Teks kanan bawah, mis. harga "Rp2,5 jt / bulan".
  final String? trailing;
  final IconData leadingIcon;
  final bool bookmarked;

  /// Null = tanpa tombol bookmark.
  final VoidCallback? onBookmark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const white = Colors.white;
    final radius = BorderRadius.circular(AppRadius.lg);
    final text = context.text;
    return DecoratedBox(
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
              right: -28,
              top: -28,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: white.withValues(alpha: .07),
                  ),
                  child: const SizedBox.square(dimension: 120),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onTap!();
                      },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s16,
                    AppSpace.s16,
                    AppSpace.s8,
                    AppSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: white.withValues(alpha: .16),
                                borderRadius: AppRadius.brMd,
                              ),
                              child: SizedBox.square(
                                dimension: 44,
                                child: Icon(leadingIcon, color: white),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppSpace.s2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: text.h3.copyWith(color: white),
                                  ),
                                  if (subtitle != null)
                                    Text(
                                      subtitle!,
                                      style: text.bodySm.copyWith(color: white),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (onBookmark != null)
                            Semantics(
                              button: true,
                              toggled: bookmarked,
                              label: bookmarked
                                  ? 'Hapus dari tersimpan'
                                  : 'Simpan lowongan',
                              excludeSemantics: true,
                              onTap: onBookmark,
                              child: InkWell(
                                onTap: onBookmark,
                                customBorder: const CircleBorder(),
                                child: SizedBox.square(
                                  dimension: AppSpace.tap,
                                  child: Icon(
                                    LucideIcons.bookmark,
                                    color: white,
                                    fill: bookmarked ? 1 : 0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (tags.isNotEmpty || trailing != null) ...[
                        const SizedBox(height: AppSpace.s12),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpace.s8),
                          child: Wrap(
                            spacing: AppSpace.s8,
                            runSpacing: AppSpace.s8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final tag in tags)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: white.withValues(alpha: .16),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.s12,
                                      vertical: AppSpace.s4,
                                    ),
                                    child: Text(
                                      tag,
                                      style: text.caption.copyWith(
                                        color: white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              if (trailing != null)
                                Text(
                                  trailing!,
                                  style: text.label.copyWith(
                                    color: white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
