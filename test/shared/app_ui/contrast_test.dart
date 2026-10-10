import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/theme/app_tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * ch(c.r) + .7152 * ch(c.g) + .0722 * ch(c.b);
}

double ratio(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final (name, t) in [
    ('light', AppTokens.light),
    ('dark', AppTokens.dark),
  ]) {
    group('kontras $name', () {
      final pairs = <(String, Color, Color, double)>[
        for (final bg in [t.canvas, t.surface, t.raised]) ...[
          ('textPrimary', t.textPrimary, bg, 4.5),
          ('textMuted (brief: >= 7)', t.textMuted, bg, 7),
          ('textSubtle', t.textSubtle, bg, 4.5),
          ('primary', t.primary, bg, 4.5),
          ('accent', t.accent, bg, 4.5),
          ('success', t.success, bg, 4.5),
          ('warning', t.warning, bg, 4.5),
          ('danger', t.danger, bg, 4.5),
        ],
        ('textMuted/sunken', t.textMuted, t.sunken, 4.5),
        ('onPrimary/primary', t.onPrimary, t.primary, 4.5),
        ('onAccent/accent', t.onAccent, t.accent, 4.5),
        ('onDanger/danger', t.onDanger, t.danger, 4.5),
        ('primary/primaryContainer', t.primary, t.primaryContainer, 4.5),
        ('textMuted/primaryContainer', t.textMuted, t.primaryContainer, 4.5),
        ('textMuted/accentContainer', t.textMuted, t.accentContainer, 4.5),
        ('accent/accentContainer', t.accent, t.accentContainer, 4.5),
        ('success/successContainer', t.success, t.successContainer, 4.5),
        ('warning/warningContainer', t.warning, t.warningContainer, 4.5),
        ('danger/dangerContainer', t.danger, t.dangerContainer, 4.5),
        ('textPrimary/dangerContainer', t.textPrimary, t.dangerContainer, 4.5),
        ('canvas/textPrimary (snackbar)', t.canvas, t.textPrimary, 4.5),
        // kontrol & ikon >= 3:1
        ('borderStrong/surface', t.borderStrong, t.surface, 3),
        ('borderStrong/canvas', t.borderStrong, t.canvas, 3),
        ('focusRing/canvas', t.focusRing, t.canvas, 3),
        ('focusRing/surface', t.focusRing, t.surface, 3),
      ];
      for (final (label, fg, bg, min) in pairs) {
        test('$label >= $min', () {
          expect(ratio(fg, bg), greaterThanOrEqualTo(min));
        });
      }
    });
  }
}
