import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

String _id(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Bintang rating.
/// - Tampil: `RatingStars(value: 4.5, count: 12)` -> "4,5 (12 ulasan)" + Semantics
///   "Rating 4,5 dari 5, 12 ulasan". Angka selalu terlihat (bukan hanya bintang).
/// - Input: beri `onChanged` -> 5 target 48dp, tiap bintang berlabel ("Beri 3 bintang").
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.count,
    this.onChanged,
    this.size,
  });

  final double value;
  final int? count;
  final ValueChanged<int>? onChanged;
  final double? size;

  bool get _input => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = size ?? (_input ? 36 : 16);
    Widget star(int i) {
      final fill = (value - i).clamp(0.0, 1.0);
      final paint = CustomPaint(
        size: Size.square(s),
        painter: _StarPainter(fill, t.accent, t.borderStrong),
      );
      if (!_input) return paint;
      return Semantics(
        button: true,
        selected: i + 1 <= value,
        label: 'Beri ${i + 1} bintang',
        excludeSemantics: true,
        onTap: () => onChanged!(i + 1),
        child: InkResponse(
          onTap: () => onChanged!(i + 1),
          radius: AppSpace.tap / 2,
          child: SizedBox(
            width: AppSpace.tap,
            height: AppSpace.tap,
            child: Center(child: paint),
          ),
        ),
      );
    }

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < 5; i++) star(i)],
    );

    if (_input) {
      return Semantics(
        container: true,
        label: 'Penilaian, ${value.round()} dari 5',
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s8,
          children: [
            stars,
            if (value > 0)
              Text('${value.round()} dari 5', style: context.text.body),
          ],
        ),
      );
    }

    final n = count;
    final reviews = n == null ? '' : ' ($n ulasan)';
    return Semantics(
      label: 'Rating ${_id(value)} dari 5${n == null ? '' : ', $n ulasan'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stars,
          const SizedBox(width: AppSpace.s8),
          Flexible(
            child: Text(
              '${_id(value)}$reviews',
              style: context.text.bodySm.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.fill, this.on, this.off);
  final double fill; // 0..1
  final Color on, off;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * .92;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * .45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (fill > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * fill, size.height));
      canvas.drawPath(path, Paint()..color = on);
      canvas.restore();
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeJoin = StrokeJoin.round
        ..color = fill > 0 ? on : off,
    );
  }

  @override
  bool shouldRepaint(_StarPainter o) =>
      o.fill != fill || o.on != on || o.off != off;
}
