import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints the additive warm glow inside the light pool.
class HaloPainter extends CustomPainter {
  /// Creates a halo painter.
  HaloPainter({
    required this.center,
    required this.radius,
    required this.intensity,
    required this.time,
    required this.warm,
    required this.inner,
  });

  /// Flame position.
  final Offset center;

  /// Light-pool radius in logical pixels.
  final double radius;

  /// `[0, 1]` flame intensity — 0 hides the halo entirely.
  final double intensity;

  /// Seconds-since-start, used to drive flicker.
  final double time;

  /// Tint color applied to the wide outer pool.
  final Color warm;

  /// Tint color applied to the bright inner core of the pool.
  final Color inner;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.01) return;
    final flick = 1.0 +
        math.sin(time * 6.3) * 0.03 +
        math.sin(time * 11.7 + 0.7) * 0.015;

    final outerR = math.max(6.0, radius * intensity * flick);
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            warm.withValues(alpha: 0.28 * intensity),
            warm.withValues(alpha: 0.08 * intensity),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    final innerR = 62.0 * intensity * flick;
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            inner.withValues(alpha: 0.6 * intensity),
            warm.withValues(alpha: 0.22 * intensity),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );
  }

  @override
  bool shouldRepaint(covariant HaloPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.intensity != intensity ||
      old.time != time ||
      old.warm != warm ||
      old.inner != inner;
}
