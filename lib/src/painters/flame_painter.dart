import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../palette.dart';

/// Paints the layered animated flame body for [CandleLight].
class FlamePainter extends CustomPainter {
  /// Creates a flame painter.
  FlamePainter({
    required this.center,
    required this.intensity,
    required this.time,
    required this.extinguished,
    required this.palette,
  });

  /// World-space flame position.
  final Offset center;

  /// `[0, 1]` flame intensity.
  final double intensity;

  /// Seconds-since-start, used by all animation phases.
  final double time;

  /// True while the flame is shrinking toward zero (controls the collapse
  /// animation — verticals compress faster than horizontals).
  final bool extinguished;

  /// Per-layer colors.
  final FlamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.01) return;

    final gust = math.sin(time * 1.3 + 0.7).abs();
    final swayAmp = 2.4 + gust * 2.2;
    final sway = math.sin(time * 3.1) * swayAmp +
        math.sin(time * 5.7 + 0.8) * 1.1 +
        math.sin(time * 11.2 + 2.3) * 0.6;

    final lickRaw = math.sin(time * 0.6 + math.sin(time * 0.35) * 2);
    final lick = math.max(0.0, (lickRaw - 0.5) / 0.5);

    final vShrink =
        extinguished ? math.pow(intensity, 1.4).toDouble() : 1.0;
    final hShrink =
        extinguished ? math.pow(intensity, 0.6).toDouble() : 1.0;

    canvas.save();
    canvas.translate(center.dx + sway * intensity, center.dy);

    _drawLayer(
      canvas,
      baseW: 20,
      baseH: 42,
      color: palette.outer,
      alpha: 0.35,
      blur: 14,
      phase: 0.0,
      freqScale: 0.9,
      hShrink: hShrink,
      vShrink: vShrink * (1 + lick * 0.12),
    );
    _drawLayer(
      canvas,
      baseW: 13,
      baseH: 32,
      color: palette.mid,
      alpha: 0.85,
      blur: 4,
      phase: 0.7,
      freqScale: 1.05,
      hShrink: hShrink,
      vShrink: vShrink * (1 + lick * 0.18),
    );
    _drawLayer(
      canvas,
      baseW: 7.5,
      baseH: 23,
      color: palette.inner,
      alpha: 1.0,
      blur: 1.4,
      phase: 1.4,
      freqScale: 1.20,
      hShrink: hShrink,
      vShrink: vShrink * (1 + lick * 0.24),
    );
    _drawLayer(
      canvas,
      baseW: 3.0,
      baseH: 12,
      color: Color.lerp(palette.core, Colors.white, intensity)!,
      alpha: 1.0,
      blur: 0,
      phase: 2.1,
      freqScale: 1.40,
      hShrink: hShrink,
      vShrink: vShrink * (1 + lick * 0.30),
    );

    final emberA = extinguished
        ? (1.0 - intensity).clamp(0.0, 1.0) * 0.6
        : 0.8 * intensity;
    if (emberA > 0.02) {
      canvas.drawCircle(
        const Offset(0, 6),
        1.6,
        Paint()
          ..color = palette.ember.withValues(alpha: emberA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    canvas.restore();
  }

  void _drawLayer(
    Canvas canvas, {
    required double baseW,
    required double baseH,
    required Color color,
    required double alpha,
    required double blur,
    required double phase,
    required double freqScale,
    required double hShrink,
    required double vShrink,
  }) {
    final t = time * freqScale;
    final pulse = 1.0 +
        math.sin(t * 8.5 + phase) * 0.05 +
        math.sin(t * 14.2 + phase + 1.3) * 0.03;

    final w = baseW * hShrink * pulse;
    final h = baseH * vShrink * pulse;
    if (w < 0.2 || h < 0.2) return;

    final path = _flamePath(w, h, t, phase);
    final paint = Paint()..color = color.withValues(alpha: alpha * intensity);
    if (blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }
    canvas.drawPath(path, paint);
  }

  Path _flamePath(double w, double h, double t, double layerPhase) {
    double s(double freq, double p) => math.sin(t * freq + p + layerPhase);

    final lBell = s(3.7, 0.0) * 0.09;
    final lMid = s(5.3, 1.1) * 0.05;
    final rBell = s(3.5, 1.7) * 0.09;
    final rMid = s(4.9, 0.4) * 0.05;

    final tipX = s(2.9, 0.9) * 0.12 + s(6.1, 2.0) * 0.035;
    final tipYBoost = 1.0 + s(2.7, 0.3) * 0.05 + s(4.1, 1.8) * 0.025;
    final th = h * tipYBoost;

    final p = Path();
    p.moveTo(-w * 0.45, h * 0.22);
    p.cubicTo(
      -w * (1.30 + lBell), 0,
      -w * (0.95 + lMid), -th * 0.35,
      -w * 0.22, -th * 0.72,
    );
    p.cubicTo(
      -w * 0.08, -th * 0.92,
      w * (tipX - 0.04), -th * 0.98,
      w * tipX, -th,
    );
    p.cubicTo(
      w * (tipX + 0.04), -th * 0.98,
      w * 0.08, -th * 0.92,
      w * 0.22, -th * 0.72,
    );
    p.cubicTo(
      w * (0.95 + rMid), -th * 0.35,
      w * (1.30 + rBell), 0,
      w * 0.45, h * 0.22,
    );
    p.quadraticBezierTo(0, h * 0.38, -w * 0.45, h * 0.22);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant FlamePainter old) =>
      old.center != center ||
      old.intensity != intensity ||
      old.time != time ||
      old.extinguished != extinguished ||
      old.palette != palette;
}
