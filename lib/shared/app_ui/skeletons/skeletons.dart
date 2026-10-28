import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../app_card.dart';
import '../app_skeleton.dart';

/// Komposisi skeleton yang meniru bentuk, ukuran, dan spasi komponen aslinya
/// agar transisi ke konten tidak meloncat. Setiap komposisi tingkat-layar
/// (`HomeSkeleton`, `DetailSkeleton`, `ProfileSkeleton`,
/// `ListSkeleton`) memasang satu [SkeletonScope] (shimmer sinkron + label
/// "Memuat"); blok kecil (`ListCardSkeleton`, `SkeletonText`) dipakai di
/// dalamnya.

/// Tinggi baris mengikuti skala teks sistem (sama seperti teks asli).
double _scaled(BuildContext c, double v) => MediaQuery.textScalerOf(c).scale(v);

const double _barRadius = 6;

/// Satu baris teks: kotak setinggi `lineHeight` (ikut skala teks) dengan batang
/// 62% tinggi di tengah. `width` null = lebar penuh * `factor`.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width,
    this.factor = 1,
    this.lineHeight = 24,
  });

  final double? width;
  final double factor;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final h = _scaled(context, lineHeight);
    final bar = AppSkeleton(
      width: width,
      height: (h * .62).roundToDouble(),
      radius: _barRadius,
    );
    return SizedBox(
      height: h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: width != null
            ? bar
            : FractionallySizedBox(widthFactor: factor, child: bar),
      ),
    );
  }
}

/// Avatar bulat.
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => AppSkeleton.box(size, radius: size / 2);
}

/// Kotak ikon lembut (kategori / baris pengaturan).
class _IconBox extends StatelessWidget {
  const _IconBox(this.size, {this.radius = AppRadius.md});
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => AppSkeleton.box(size, radius: radius);
}

/// Jenis kartu/baris daftar.
enum SkeletonCardKind {
  /// Kartu lowongan (ikon, judul, meta, anggaran, chip, footer).
  listing,

  /// Kartu asisten (avatar, nama, 2 meta, footer rating + tarif).
  assistant,

  /// Kartu ringkas beranda (chip status, judul, kota, baris aksi).
  summary,

  /// Baris percakapan chat (tanpa kartu).
  conversation,

  /// Baris riwayat transaksi (tanpa kartu).
  transaction,

  /// Baris notifikasi (tanpa kartu).
  notification,
}

/// Satu item daftar sesuai [kind]. Tanpa scope/semantik sendiri: bungkus dengan
/// [SkeletonScope] atau pakai [ListSkeleton].
class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({super.key, this.kind = SkeletonCardKind.listing});
  final SkeletonCardKind kind;

  @override
  Widget build(BuildContext context) => switch (kind) {
    SkeletonCardKind.listing => _listing(context),
    SkeletonCardKind.assistant => _assistant(context),
    SkeletonCardKind.summary => _summary(context),
    SkeletonCardKind.conversation => _row(
      context,
      lead: const SkeletonAvatar(48),
      lines: const [
        SkeletonText(width: 140),
        SizedBox(height: AppSpace.s4),
        SkeletonText(factor: .8, lineHeight: 20),
      ],
      trailing: const SkeletonText(width: 36, lineHeight: 16),
    ),
    SkeletonCardKind.transaction => _row(
      context,
      lead: const _IconBox(40),
      lines: const [
        SkeletonText(factor: .6),
        SizedBox(height: AppSpace.s4),
        SkeletonText(width: 90, lineHeight: 16),
      ],
      trailing: const SkeletonText(width: 80),
      start: true,
    ),
    SkeletonCardKind.notification => _row(
      context,
      lead: const _IconBox(40),
      lines: const [
        SkeletonText(factor: .5, lineHeight: 20),
        SizedBox(height: AppSpace.s2),
        SkeletonText(factor: .9, lineHeight: 20),
        SizedBox(height: AppSpace.s4),
        SkeletonText(width: 60, lineHeight: 16),
      ],
      start: true,
    ),
  };

  static Widget _row(
    BuildContext context, {
    required Widget lead,
    required List<Widget> lines,
    Widget? trailing,
    bool start = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.s16,
      vertical: AppSpace.s12,
    ),
    child: Row(
      crossAxisAlignment: start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        lead,
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.s12),
          trailing,
        ],
      ],
    ),
  );

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: context.tokens.borderSubtle);

  Widget _pill(double w) =>
      AppSkeleton(width: w, height: 28, radius: AppRadius.lg);

  Widget _listing(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(48),
            SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(factor: .7),
                  SizedBox(height: AppSpace.s2),
                  SkeletonText(factor: .5, lineHeight: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        const SkeletonText(width: 190),
        const SkeletonText(width: 130, lineHeight: 20),
        const SizedBox(height: AppSpace.s12),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          children: [_pill(96), _pill(80)],
        ),
        const SizedBox(height: AppSpace.s12),
        _divider(context),
        const SizedBox(height: AppSpace.s12),
        const Row(
          children: [
            SkeletonText(width: 90, lineHeight: 20),
            SizedBox(width: AppSpace.s16),
            SkeletonText(width: 64, lineHeight: 20),
          ],
        ),
      ],
    ),
  );

  Widget _assistant(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SkeletonAvatar(56),
            SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 150),
                  SizedBox(height: AppSpace.s4),
                  SkeletonText(width: 110, lineHeight: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        const SkeletonText(factor: .7, lineHeight: 20),
        const SizedBox(height: AppSpace.s4),
        const SkeletonText(factor: .45, lineHeight: 20),
        const SizedBox(height: AppSpace.s12),
        _divider(context),
        const SizedBox(height: AppSpace.s12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonText(width: 96, lineHeight: 20),
            SkeletonText(width: 120),
          ],
        ),
      ],
    ),
  );

  Widget _summary(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_pill(88)]),
        const SizedBox(height: AppSpace.s12),
        const SkeletonText(factor: .65),
        const SizedBox(height: AppSpace.s4),
        const SkeletonText(factor: .45, lineHeight: 20),
        const SizedBox(height: AppSpace.s12),
        const Row(
          children: [
            AppSkeleton.box(18, radius: 9),
            SizedBox(width: AppSpace.s8),
            SkeletonText(width: 120, lineHeight: 20),
          ],
        ),
      ],
    ),
  );
}

/// Daftar skeleton generik (satu scope, satu "Memuat"). API lama dipertahankan;
/// `kind` memilih bentuk item.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.count = 4,
    this.kind = SkeletonCardKind.listing,
  });
  final int count;
  final SkeletonCardKind kind;

  bool get _grouped =>
      kind == SkeletonCardKind.conversation ||
      kind == SkeletonCardKind.transaction ||
      kind == SkeletonCardKind.notification;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final Widget body = _grouped
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: t.borderSubtle),
              boxShadow: t.e1,
            ),
            child: Column(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent:
                          AppSpace.s16 +
                          (kind == SkeletonCardKind.conversation ? 48 : 40) +
                          AppSpace.s12,
                      color: t.borderSubtle,
                    ),
                  ListCardSkeleton(kind: kind),
                ],
              ],
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < count; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == count - 1 ? 0 : AppSpace.s12,
                  ),
                  child: ListCardSkeleton(kind: kind),
                ),
            ],
          );
    return SkeletonScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        child: body,
      ),
    );
  }
}

/// Heading seksi (`SectionHeader`: padding v8 + h2).
class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton({this.width = 140});
  final double width;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
    child: SkeletonText(width: width, lineHeight: 28),
  );
}

/// Kepala beranda (`HomeHeader`): avatar 44 di kotak tap 48, dua baris teks, lonceng.
/// Scope sendiri tanpa label (label "Memuat" sudah dari [HomeSkeleton]).
class HomeHeaderSkeleton extends StatelessWidget {
  const HomeHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    semantics: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s8,
        AppSpace.s8,
        AppSpace.s4,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: AppSpace.tap,
            child: Center(child: SkeletonAvatar(44)),
          ),
          SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 140, lineHeight: 28),
                SkeletonText(width: 200, lineHeight: 20),
              ],
            ),
          ),
          SizedBox.square(
            dimension: AppSpace.tap,
            child: Center(child: SkeletonAvatar(28)),
          ),
        ],
      ),
    ),
  );
}

/// Beranda: SearchField, 4 CategoryTile, HeroBannerCard, judul seksi, 2 kartu.
/// Padding 16 (ListView beranda); letakkan di body `padded: false`.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key, this.cards = 2});
  final int cards;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final searchH = (_scaled(context, 24) + 32).clamp(48.0, 200.0);
    return SkeletonScope(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SearchField.
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.borderSubtle),
                boxShadow: t.e1,
              ),
              child: SizedBox(
                height: searchH,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.s16),
                  child: Row(
                    children: [
                      AppSkeleton.box(20, radius: 10),
                      SizedBox(width: AppSpace.s12),
                      SkeletonText(width: 120),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            // Baris 4 CategoryTile.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 4; i++)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpace.s4),
                      child: Column(
                        children: [
                          _IconBox(56, radius: AppRadius.card),
                          SizedBox(height: AppSpace.s8),
                          Align(child: SkeletonText(width: 56, lineHeight: 20)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s20),
            const _HeroBannerSkeleton(),
            const SizedBox(height: AppSpace.s16),
            const _SectionHeaderSkeleton(),
            for (var i = 0; i < cards; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpace.s12),
                child: ListCardSkeleton(kind: SkeletonCardKind.summary),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroBannerSkeleton extends StatelessWidget {
  const _HeroBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.heroSoftFrom, t.heroSoftTo],
        ),
        border: Border.all(
          color: t.isDark
              ? t.borderSubtle
              : t.primaryBright.withValues(alpha: .25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: LayoutBuilder(
          builder: (context, c) {
            final art = c.maxWidth >= 300;
            return Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(factor: .75, lineHeight: 28),
                      SizedBox(height: AppSpace.s4),
                      SkeletonText(factor: .9, lineHeight: 20),
                      SizedBox(height: AppSpace.s16),
                      AppSkeleton(
                        width: 112,
                        height: 36,
                        radius: AppRadius.button,
                      ),
                    ],
                  ),
                ),
                if (art) ...[
                  const SizedBox(width: AppSpace.s8),
                  const SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(
                      child: AppSkeleton.box(96, radius: AppRadius.lg),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Detail (lowongan/kontrak/lamaran): hero info, chip status, tab, paragraf, kartu info.
/// Tanpa padding horizontal (AppScaffold sudah memberi 16).
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SkeletonScope(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(56, radius: AppRadius.card),
                SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(factor: .8, lineHeight: 34),
                      SizedBox(height: AppSpace.s4),
                      SkeletonText(width: 110, lineHeight: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            const Row(
              children: [
                AppSkeleton(width: 96, height: 28, radius: AppRadius.lg),
                SizedBox(width: AppSpace.s8),
                SkeletonText(width: 80, lineHeight: 20),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            // Tab segmen.
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.sunken,
                borderRadius: AppRadius.brButton,
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpace.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSkeleton(height: 40, radius: AppRadius.md),
                    ),
                    SizedBox(width: AppSpace.s8),
                    Expanded(child: SkeletonText(factor: .5, lineHeight: 40)),
                    SizedBox(width: AppSpace.s8),
                    Expanded(child: SkeletonText(factor: .5, lineHeight: 40)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            const SkeletonText(width: 160, lineHeight: 28),
            const SizedBox(height: AppSpace.s8),
            const SkeletonText(lineHeight: 24),
            const SkeletonText(lineHeight: 24),
            const SkeletonText(factor: .9, lineHeight: 24),
            const SkeletonText(factor: .55, lineHeight: 24),
            const SizedBox(height: AppSpace.s16),
            const AppCard(
              child: Column(
                children: [
                  _InfoRowSkeleton(),
                  SizedBox(height: AppSpace.s12),
                  _InfoRowSkeleton(),
                  SizedBox(height: AppSpace.s12),
                  _InfoRowSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRowSkeleton extends StatelessWidget {
  const _InfoRowSkeleton();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      AppSkeleton.box(20, radius: 6),
      SizedBox(width: AppSpace.s12),
      Expanded(child: SkeletonText(factor: .6, lineHeight: 20)),
    ],
  );
}

/// Profil: kartu identitas, StatsRow, judul seksi, grup baris pengaturan.
/// Tanpa padding horizontal (AppScaffold memberi 16); bungkus Padding bila `padded: false`.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            child: Row(
              children: [
                SkeletonAvatar(64),
                SizedBox(width: AppSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 160, lineHeight: 28),
                      SkeletonText(width: 120, lineHeight: 20),
                      SizedBox(height: AppSpace.s8),
                      AppSkeleton(width: 112, height: 28, radius: AppRadius.lg),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          // StatsRow.
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: t.borderSubtle),
              boxShadow: t.e1,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Expanded(
                      child: Column(
                        children: [
                          Align(child: SkeletonText(width: 40, lineHeight: 28)),
                          SizedBox(height: AppSpace.s2),
                          Align(child: SkeletonText(width: 64, lineHeight: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          const _SectionHeaderSkeleton(width: 120),
          const SizedBox(height: AppSpace.s8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: t.borderSubtle),
              boxShadow: t.e1,
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpace.s16 + 40 + AppSpace.s12,
                      color: t.borderSubtle,
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpace.s16,
                        vertical: AppSpace.s12,
                      ),
                      child: Row(
                        children: [
                          _IconBox(40),
                          SizedBox(width: AppSpace.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonText(factor: .55),
                                SkeletonText(factor: .35, lineHeight: 20),
                              ],
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
        ],
      ),
    );
  }
}

/// Loading blok kecil sebaris (mis. perkiraan biaya, tombol aksi).
class InlineSkeleton extends StatelessWidget {
  const InlineSkeleton({super.key, this.width, this.height = 20, this.radius});
  final double? width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: AppSkeleton(
      width: width,
      height: height,
      radius: radius ?? _barRadius,
    ),
  );
}
