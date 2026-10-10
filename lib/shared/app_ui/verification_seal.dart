import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

enum SealState { pending, verified, rejected }

enum SealSize {
  sm(16),
  md(24),
  lg(48);

  const SealSize(this.px);
  final double px;
}

/// Segel soga khas Buku Kas Rumah: stempel bergerigi + cincin dalam + ikon.
/// Selalu disertai teks ("Terverifikasi") kecuali `showLabel: false`.
/// `stamp: true` memainkan animasi "cap" 0,9 -> 1 sekali (layar status verifikasi).
class VerificationSeal extends StatelessWidget {
  const VerificationSeal({
    super.key,
    this.state = SealState.verified,
    this.size = SealSize.md,
    this.showLabel = true,
    this.stamp = false,
    this.onTap,
  });

  final SealState state;
  final SealSize size;
  final bool showLabel;
  final bool stamp;

  /// Biasanya membuka sheet "Apa arti terverifikasi?".
  final VoidCallback? onTap;

  static String labelFor(SealState s) => switch (s) {
    SealState.pending => 'Menunggu tinjauan',
    SealState.verified => 'Terverifikasi',
    SealState.rejected => 'Ditolak',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (ink, fill, icon) = switch (state) {
      SealState.verified => (
        t.accent,
        t.accentContainer,
        LucideIcons.shieldCheck,
      ),
      SealState.pending => (t.textMuted, t.sunken, LucideIcons.clock),
      SealState.rejected => (t.danger, t.dangerContainer, LucideIcons.shieldX),
    };
    final px = size.px;
    Widget seal = SizedBox.square(
      dimension: px,
      child: CustomPaint(
        painter: _SealPainter(ink, fill, px >= 24),
        child: Center(
          child: Icon(icon, size: px * .52, color: ink),
        ),
      ),
    );
    if (stamp && state == SealState.verified) {
      seal = TweenAnimationBuilder<double>(
        tween: Tween(begin: .9, end: 1),
        duration: context.motion(AppMotion.slow),
        curve: AppMotion.enter,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: seal,
      );
    }
    final label = labelFor(state);
    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: seal),
        if (showLabel) ...[
          SizedBox(
            width: size == SealSize.lg ? AppSpace.s12 : AppSpace.s4 * 1.5,
          ),
          Flexible(
            child: Text(
              label,
              style:
                  (size == SealSize.lg ? context.text.h3 : context.text.bodySm)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
            ),
          ),
        ],
      ],
    );
    if (onTap != null) {
      row = InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.tap),
          child: Center(widthFactor: 1, child: row),
        ),
      );
    }
    return Semantics(
      label: 'Segel ${label.toLowerCase()}',
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: row,
    );
  }
}

class _SealPainter extends CustomPainter {
  _SealPainter(this.ink, this.fill, this.ring);
  final Color ink, fill;
  final bool ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Tepi bergerigi: r(θ) = R(0.94 + 0.06 cos(12θ))
    final path = Path();
    for (var i = 0; i <= 144; i++) {
      final a = 2 * math.pi * i / 144;
      final rr = r * (.94 + .06 * math.cos(12 * a));
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    final w = math.max(1.0, size.width / 20);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = ink,
    );
    if (ring) {
      canvas.drawCircle(
        c,
        r * .76,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .6
          ..color = ink.withValues(alpha: .5),
      );
    }
  }

  @override
  bool shouldRepaint(_SealPainter o) =>
      o.ink != ink || o.fill != fill || o.ring != ring;
}
