import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Ilustrasi vektor flat (CustomPaint), tanpa aset/unduhan, tanpa orang realistis.
/// Palet dari token (biru, putih, aksen oranye) dan ikut mode gelap. Semua dekoratif:
/// dikecualikan dari semantics. `size` = lebar; tinggi = 0,8 x lebar.

/// Palet ilustrasi diturunkan dari token.
class _P {
  _P(AppTokens t)
    : primary = t.primary,
      onPrimary = t.onPrimary,
      bright = t.primaryBright,
      soft = t.illoSoft,
      accent = t.illoAccent,
      ink = t.illoInk,
      paper = t.illoPaper;

  final Color primary, onPrimary, bright, soft, accent, ink, paper;
}

typedef _Draw = void Function(Canvas c, _P p);

class _Illo extends StatelessWidget {
  const _Illo({required this.size, required this.draw});

  final double size;
  final _Draw draw;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size * .8,
        child: CustomPaint(painter: _IlloPainter(_P(context.tokens), draw)),
      ),
    ),
  );
}

class _IlloPainter extends CustomPainter {
  _IlloPainter(this.p, this.draw);

  final _P p;
  final _Draw draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200);
    draw(canvas, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IlloPainter o) => true;
}

// ---- helper gambar ---------------------------------------------------------

Paint _f(Color c) => Paint()..color = c;

Paint _s(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _rr(Canvas c, double x, double y, double w, double h, double r, Paint p) =>
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      p,
    );

void _blob(Canvas c, _P p) {
  c.drawOval(
    Rect.fromLTWH(12, 10, 176, 138),
    _f(p.soft.withValues(alpha: .55)),
  );
  c.drawCircle(const Offset(168, 30), 9, _f(p.soft.withValues(alpha: .8)));
}

/// Kartu kertas dengan tepi tipis.
void _paper(Canvas c, _P p, double x, double y, double w, double h, double r) {
  _rr(c, x, y, w, h, r, _f(p.paper));
  _rr(c, x, y, w, h, r, _s(p.bright.withValues(alpha: .45), 1.5));
}

void _sparkle(Canvas c, double x, double y, double r, Color col) {
  final path = Path()
    ..moveTo(x, y - r)
    ..quadraticBezierTo(x, y, x + r, y)
    ..quadraticBezierTo(x, y, x, y + r)
    ..quadraticBezierTo(x, y, x - r, y)
    ..quadraticBezierTo(x, y, x, y - r)
    ..close();
  c.drawPath(path, _f(col));
}

void _check(Canvas c, double cx, double cy, double r, Color col) {
  final path = Path()
    ..moveTo(cx - r * .45, cy + r * .02)
    ..lineTo(cx - r * .1, cy + r * .38)
    ..lineTo(cx + r * .5, cy - r * .32);
  c.drawPath(path, _s(col, r * .28));
}

Path _shieldPath(double cx, double top, double w) {
  final h = w * 1.15;
  return Path()
    ..moveTo(cx, top)
    ..lineTo(cx + w / 2, top + h * .14)
    ..lineTo(cx + w / 2, top + h * .5)
    ..quadraticBezierTo(cx + w / 2, top + h * .86, cx, top + h)
    ..quadraticBezierTo(cx - w / 2, top + h * .86, cx - w / 2, top + h * .5)
    ..lineTo(cx - w / 2, top + h * .14)
    ..close();
}

void _shield(Canvas c, _P p, double cx, double top, double w) {
  final path = _shieldPath(cx, top, w);
  c.drawPath(path, _f(p.primary));
  c.drawPath(path, _s(p.paper, w * .07));
  _check(c, cx, top + w * .56, w * .5, p.onPrimary);
}

void _confetti(
  Canvas c,
  double x,
  double y,
  double w,
  double h,
  double angle,
  Color col,
) {
  c.save();
  c.translate(x, y);
  c.rotate(angle);
  _rr(c, -w / 2, -h / 2, w, h, math.min(w, h) / 2.5, _f(col));
  c.restore();
}

// ---- ilustrasi -------------------------------------------------------------

/// Sambutan: kartu aplikasi + kartu unggulan + lencana perisai.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, this.size = 240});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _welcome);

  static void _welcome(Canvas c, _P p) {
    _blob(c, p);
    _paper(c, p, 52, 22, 96, 118, 14);
    c.drawCircle(const Offset(72, 46), 10, _f(p.primary));
    _rr(c, 88, 38, 44, 6, 3, _f(p.ink.withValues(alpha: .75)));
    _rr(c, 88, 50, 30, 5, 2.5, _f(p.soft));
    for (var i = 0; i < 3; i++) {
      final y = 72.0 + i * 22;
      _rr(c, 62, y, 76, 17, 8.5, _f(p.soft.withValues(alpha: .6)));
      c.drawCircle(Offset(72, y + 8.5), 4.5, _f(i == 1 ? p.accent : p.bright));
      _rr(c, 83, y + 6, 42, 5, 2.5, _f(p.ink.withValues(alpha: .45)));
    }
    // kartu unggulan
    _rr(c, 120, 12, 58, 36, 10, _f(p.primary));
    _rr(c, 128, 22, 30, 5, 2.5, _f(p.onPrimary.withValues(alpha: .9)));
    _rr(c, 128, 32, 20, 4, 2, _f(p.onPrimary.withValues(alpha: .55)));
    _rr(c, 164, 12, 8, 15, 2, _f(p.accent));
    // lencana perisai
    _shield(c, p, 48, 100, 38);
    _sparkle(c, 172, 100, 8, p.accent);
    _sparkle(c, 30, 52, 5, p.bright);
    c.drawCircle(const Offset(168, 128), 4, _f(p.bright));
  }
}

/// Sukses: lingkaran berisi centang + konfeti sederhana.
class SuccessIllustration extends StatelessWidget {
  const SuccessIllustration({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _success);

  static void _success(Canvas c, _P p) {
    _blob(c, p);
    c.drawCircle(
      const Offset(100, 76),
      52,
      _s(p.bright.withValues(alpha: .45), 3),
    );
    c.drawCircle(const Offset(100, 76), 40, _f(p.primary));
    _check(c, 100, 76, 40, p.onPrimary);
    _confetti(c, 40, 34, 14, 6, .6, p.accent);
    _confetti(c, 160, 40, 12, 6, -.8, p.bright);
    _confetti(c, 30, 98, 10, 5, -.4, p.bright);
    _confetti(c, 172, 100, 14, 6, .9, p.accent);
    _confetti(c, 66, 128, 12, 5, .3, p.accent);
    _confetti(c, 142, 130, 10, 5, -.5, p.ink.withValues(alpha: .7));
    c.drawCircle(const Offset(52, 62), 4, _f(p.bright));
    c.drawCircle(const Offset(150, 14), 4, _f(p.accent));
    c.drawCircle(const Offset(182, 70), 3.5, _f(p.ink.withValues(alpha: .6)));
    _sparkle(c, 124, 22, 7, p.accent);
    _sparkle(c, 78, 20, 5, p.bright);
  }
}

/// Kosong: dokumen + kaca pembesar.
class EmptyListIllustration extends StatelessWidget {
  const EmptyListIllustration({super.key, this.size = 200});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _empty);

  static void _empty(Canvas c, _P p) {
    _blob(c, p);
    _paper(c, p, 56, 22, 80, 108, 10);
    c.drawPath(
      Path()
        ..moveTo(114, 22)
        ..lineTo(136, 44)
        ..lineTo(114, 44)
        ..close(),
      _f(p.soft),
    );
    _rr(c, 70, 36, 28, 7, 3.5, _f(p.bright));
    _rr(c, 70, 60, 52, 6, 3, _f(p.soft));
    _rr(c, 70, 74, 40, 6, 3, _f(p.soft));
    _rr(c, 70, 88, 48, 6, 3, _f(p.soft));
    // kaca pembesar
    c.drawLine(const Offset(146, 118), const Offset(168, 140), _s(p.ink, 9));
    c.drawCircle(const Offset(128, 100), 22, _f(p.paper.withValues(alpha: .9)));
    c.drawCircle(const Offset(128, 100), 22, _s(p.primary, 7));
    _rr(c, 117, 98, 22, 5, 2.5, _f(p.accent));
    _sparkle(c, 40, 60, 7, p.accent);
    c.drawCircle(const Offset(168, 54), 4, _f(p.bright));
  }
}

/// Verifikasi: kartu identitas + perisai centang.
class VerifyIllustration extends StatelessWidget {
  const VerifyIllustration({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _verify);

  static void _verify(Canvas c, _P p) {
    _blob(c, p);
    _paper(c, p, 30, 36, 116, 82, 12);
    c.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(30, 36, 116, 22),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
      ),
      _f(p.primary),
    );
    _rr(c, 42, 43, 36, 6, 3, _f(p.onPrimary.withValues(alpha: .85)));
    c.drawCircle(const Offset(60, 86), 15, _f(p.soft));
    c.drawCircle(const Offset(60, 81), 5.5, _f(p.primary));
    _rr(c, 51, 89, 18, 9, 4.5, _f(p.primary));
    _rr(c, 86, 74, 46, 6, 3, _f(p.ink.withValues(alpha: .7)));
    _rr(c, 86, 88, 34, 5, 2.5, _f(p.soft));
    _rr(c, 86, 100, 40, 5, 2.5, _f(p.soft));
    _shield(c, p, 142, 84, 46);
    _sparkle(c, 170, 36, 8, p.accent);
    c.drawCircle(const Offset(26, 128), 4, _f(p.bright));
    _sparkle(c, 40, 20, 5, p.bright);
  }
}

/// Dana aman: dompet + koin + perisai.
class MoneySafeIllustration extends StatelessWidget {
  const MoneySafeIllustration({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _money);

  static void _money(Canvas c, _P p) {
    _blob(c, p);
    c.drawCircle(const Offset(80, 50), 17, _f(p.accent));
    c.drawCircle(
      const Offset(80, 50),
      10,
      _s(p.paper.withValues(alpha: .8), 2.5),
    );
    c.drawCircle(
      const Offset(116, 42),
      14,
      _f(p.accent.withValues(alpha: .75)),
    );
    c.drawCircle(
      const Offset(116, 42),
      8,
      _s(p.paper.withValues(alpha: .8), 2.5),
    );
    _rr(c, 38, 56, 116, 70, 14, _f(p.primary));
    _rr(c, 38, 56, 116, 20, 10, _f(p.bright));
    _rr(c, 120, 86, 44, 28, 10, _f(p.ink));
    c.drawCircle(const Offset(136, 100), 5.5, _f(p.accent));
    _sparkle(c, 172, 40, 7, p.accent);
    c.drawCircle(const Offset(28, 40), 4, _f(p.bright));
    // perisai di depan
    final sh = _shieldPath(70, 88, 40);
    c.drawPath(sh, _f(p.paper));
    c.drawPath(sh, _s(p.primary, 4));
    _check(c, 70, 110, 20, p.primary);
  }
}

/// Obrolan: dua gelembung pesan.
class ChatIllustration extends StatelessWidget {
  const ChatIllustration({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) => _Illo(size: size, draw: _chat);

  static void _chat(Canvas c, _P p) {
    _blob(c, p);
    // gelembung kiri (kertas)
    _paper(c, p, 30, 30, 100, 50, 16);
    c.drawPath(
      Path()
        ..moveTo(46, 78)
        ..lineTo(42, 96)
        ..lineTo(66, 79)
        ..close(),
      _f(p.paper),
    );
    c.drawCircle(const Offset(62, 55), 5.5, _f(p.bright));
    c.drawCircle(const Offset(80, 55), 5.5, _f(p.accent));
    c.drawCircle(const Offset(98, 55), 5.5, _f(p.bright));
    // gelembung kanan (primer)
    _rr(c, 72, 92, 100, 44, 16, _f(p.primary));
    c.drawPath(
      Path()
        ..moveTo(150, 134)
        ..lineTo(158, 150)
        ..lineTo(130, 135)
        ..close(),
      _f(p.primary),
    );
    _rr(c, 88, 104, 60, 6, 3, _f(p.onPrimary.withValues(alpha: .9)));
    _rr(c, 88, 118, 40, 6, 3, _f(p.onPrimary.withValues(alpha: .6)));
    _sparkle(c, 168, 34, 8, p.accent);
    c.drawCircle(const Offset(24, 120), 4, _f(p.bright));
  }
}
