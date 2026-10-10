import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_theme.dart';

/// Pembungkus skeleton: satu controller shimmer untuk SEMUA [AppSkeleton] di
/// bawahnya (sapuan miring ~1,4 dtk yang menyambung antar-kotak), satu
/// `Semantics(liveRegion, label: 'Memuat')`, dan isi disembunyikan dari screen
/// reader. Diam (tanpa sapuan) bila reduce motion. Tanpa paket tambahan.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child, this.semantics = true});

  final Widget child;

  /// `false` bila pembungkus lain sudah memberi label "Memuat".
  final bool semantics;

  static _ShimmerSpec? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerInherited>()?.spec;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    if (_animate) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  RenderBox? _box() {
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Terang: antara sunken dan borderSubtle agar terbaca di kanvas maupun
    // kartu putih; gelap: sunken. Highlight = lapis putih tipis.
    final base = t.isDark
        ? t.sunken
        : Color.lerp(t.sunken, t.borderSubtle, .5)!;
    final highlight = Colors.white.withValues(alpha: t.isDark ? .07 : .8);
    final spec = _ShimmerSpec(
      t: _c,
      animate: _animate,
      base: base,
      peak: Color.alphaBlend(highlight, base),
      box: _box,
    );
    Widget child = ExcludeSemantics(child: widget.child);
    if (widget.semantics) {
      child = Semantics(liveRegion: true, label: 'Memuat', child: child);
    }
    return _ShimmerInherited(spec: spec, child: child);
  }
}

class _ShimmerSpec {
  const _ShimmerSpec({
    required this.t,
    required this.animate,
    required this.base,
    required this.peak,
    required this.box,
  });

  final Animation<double> t;
  final bool animate;
  final Color base, peak;
  final RenderBox? Function() box;
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({required this.spec, required super.child});
  final _ShimmerSpec spec;

  @override
  bool updateShouldNotify(_ShimmerInherited old) =>
      old.spec.animate != spec.animate ||
      old.spec.base != spec.base ||
      old.spec.peak != spec.peak ||
      old.spec.t != spec.t;
}

/// Placeholder bentuk-konten. Shimmer berasal dari [SkeletonScope] terdekat;
/// tanpa scope ia membuat scope sendiri (tanpa semantik).
class AppSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final spec = SkeletonScope._maybeOf(context);
    if (spec == null) {
      return SkeletonScope(
        semantics: false,
        child: AppSkeleton(width: width, height: height, radius: radius),
      );
    }
    return _Bone(spec: spec, width: width, height: height, radius: radius);
  }
}

class _Bone extends LeafRenderObjectWidget {
  const _Bone({
    required this.spec,
    required this.width,
    required this.height,
    required this.radius,
  });

  final _ShimmerSpec spec;
  final double? width;
  final double height, radius;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBone(spec, width, height, radius);

  @override
  void updateRenderObject(BuildContext context, _RenderBone ro) => ro
    ..spec = spec
    ..w = width
    ..h = height
    ..radius = radius;
}

class _RenderBone extends RenderBox {
  _RenderBone(this._spec, this._w, this._h, this._radius);

  static const _band = 240.0;
  static const _tilt = .35; // rad (~20 derajat dari vertikal)

  _ShimmerSpec _spec;
  double? _w;
  double _h, _radius;

  set spec(_ShimmerSpec v) {
    if (identical(v, _spec)) return;
    if (attached) _spec.t.removeListener(markNeedsPaint);
    _spec = v;
    if (attached) v.t.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set w(double? v) {
    if (v == _w) return;
    _w = v;
    markNeedsLayout();
  }

  set h(double v) {
    if (v == _h) return;
    _h = v;
    markNeedsLayout();
  }

  set radius(double v) {
    if (v == _radius) return;
    _radius = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _spec.t.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _spec.t.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints c) =>
      c.constrain(Size(_w ?? (c.hasBoundedWidth ? c.maxWidth : 0), _h));

  @override
  void performLayout() => size = computeDryLayout(constraints);

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final s = _spec;
    final paint = Paint()..color = s.base;
    final scope = s.animate ? s.box() : null;
    if (scope != null && scope.attached) {
      final origin = localToGlobal(Offset.zero, ancestor: scope);
      final d = Offset(math.cos(_tilt), math.sin(_tilt));
      final extent = scope.size.width * d.dx + scope.size.height * d.dy;
      final start = -_band + (extent + _band) * s.t.value;
      // Titik (dalam koordinat scope) pada sumbu sapuan -> koordinat kanvas.
      final from = offset + d * start - origin;
      final to = offset + d * (start + _band) - origin;
      final soft = Color.lerp(s.base, s.peak, .4)!;
      paint.shader = ui.Gradient.linear(
        from,
        to,
        [s.base, soft, s.peak, soft, s.base],
        const [0, .3, .5, .7, 1],
      );
    }
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(offset & size, Radius.circular(_radius)),
      paint,
    );
  }
}
