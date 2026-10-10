import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Placeholder bentuk-konten dengan pulsa halus 1,2 dtk (tanpa paket shimmer).
/// Diam bila reduce motion. Disembunyikan dari screen reader; beri satu
/// `Semantics(label: 'Memuat')` di pembungkus daftar.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.xs,
  });

  /// Baris teks 16dp (lebar penuh bila `width` null).
  const AppSkeleton.line({super.key, this.width, this.height = 16})
    : radius = AppRadius.xs;

  /// Kotak/foto (mis. avatar `AppSkeleton.box(48, radius: 24)`).
  const AppSkeleton.box(double size, {super.key, this.radius = AppRadius.sm})
    : width = size,
      height = size;

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    if (_animate) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Opacity(
          opacity: _animate
              ? 1 - .5 * Curves.easeInOut.transform(_c.value)
              : .75,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: t.borderSubtle,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
        ),
      ),
    );
  }
}
