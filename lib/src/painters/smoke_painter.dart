import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/smoke_particle.dart';

/// Paints a list of rising smoke wisps.
class SmokePainter extends CustomPainter {
  /// Creates a smoke painter that renders the supplied [particles].
  SmokePainter({required this.particles});

  /// The live particles to render.
  final List<SmokeParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = p.t;
      final fadeIn = math.min(1.0, t * 5);
      final fadeOut = 1.0 - t;
      final alpha = (fadeIn * fadeOut * 0.55).clamp(0.0, 1.0);
      if (alpha < 0.01) continue;
      final sz = p.initialSize * (1.0 + t * 3.5);
      final color = Color.lerp(
        const Color(0xFFD0D0D0),
        const Color(0xFF5A5A5A),
        t,
      )!
          .withValues(alpha: alpha);
      canvas.drawCircle(
        p.pos,
        sz,
        Paint()
          ..color = color
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, 2.5 + sz * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SmokePainter old) => true;
}
