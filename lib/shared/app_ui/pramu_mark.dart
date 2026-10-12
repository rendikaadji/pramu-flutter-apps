import 'package:flutter/widgets.dart';

/// Logo Pramu "Lipatan": P dari bidang berlipat di atas ubin biru langit.
/// Geometri sama dengan ikon launcher (kotak 120 satuan, glyph berpusat di 61,60).
class PramuMark extends StatelessWidget {
  const PramuMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 120;
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(28 * u),
    );
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA9C8F4), Color(0xFF4F7BBF)],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.scale(u);
    Paint p(int c) => Paint()..color = Color(c);
    canvas.drawRect(const Rect.fromLTRB(36, 28, 54, 92), p(0xFFFFFFFF));
    final top = Path()
      ..moveTo(54, 28)
      ..lineTo(66, 28)
      ..arcToPoint(const Offset(86, 48), radius: const Radius.circular(20))
      ..lineTo(54, 48)
      ..close();
    final bottom = Path()
      ..moveTo(54, 48)
      ..lineTo(86, 48)
      ..arcToPoint(
        const Offset(66, 68),
        radius: const Radius.circular(20),
        clockwise: true,
      )
      ..lineTo(54, 68)
      ..close();
    final fold = Path()
      ..moveTo(36, 92)
      ..lineTo(54, 68)
      ..lineTo(54, 92)
      ..close();
    canvas.drawPath(top, p(0xFFE4ECF7));
    canvas.drawPath(bottom, p(0xFFB9D2F5));
    canvas.drawPath(fold, p(0xFF244C7C));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}
