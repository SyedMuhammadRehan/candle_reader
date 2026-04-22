import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints [dimColor] across the widget with a soft-edged circular hole
/// around [center].
class SpotlightPainter extends CustomPainter {
  /// Creates a spotlight painter.
  SpotlightPainter({
    required this.center,
    required this.radius,
    required this.intensity,
    required this.time,
    required this.dimColor,
  });

  /// Flame position.
  final Offset center;

  /// Light-pool radius in logical pixels.
  final double radius;

  /// `[0, 1]` flame intensity — at 0 the hole closes and the widget goes
  /// fully dim.
  final double intensity;

  /// Seconds-since-start, used to drive flicker.
  final double time;

  /// Color painted outside the light pool.
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final flick = 1.0 +
        math.sin(time * 7.1) * 0.028 +
        math.sin(time * 13.3 + 1.2) * 0.014;
    final effR = radius * intensity * flick;

    if (effR < 2) {
      canvas.drawRect(bounds, Paint()..color = dimColor);
      return;
    }

    final shortest = size.shortestSide;
    final ax = (center.dx / size.width) * 2 - 1;
    final ay = (center.dy / size.height) * 2 - 1;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(ax, ay),
        radius: effR / shortest,
        colors: <Color>[
          dimColor.withValues(alpha: 0),
          dimColor.withValues(alpha: 0),
          dimColor.withValues(alpha: 0.45),
          dimColor.withValues(alpha: 0.92),
          dimColor,
        ],
        stops: const <double>[0.0, 0.28, 0.58, 0.88, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.intensity != intensity ||
      old.time != time ||
      old.dimColor != dimColor;
}
