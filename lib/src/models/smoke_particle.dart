import 'dart:math' as math;
import 'dart:ui';

/// A single wisp of smoke rising from an extinguished flame.
class SmokeParticle {
  /// Creates a smoke particle.
  SmokeParticle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.initialSize,
    required this.phase,
    required this.drift,
  });

  /// Current world-space position of the wisp, in logical pixels.
  Offset pos;

  /// Linear velocity. Only the vertical component is integrated each
  /// frame; horizontal motion is driven by [drift] and [phase].
  Offset vel;

  /// Seconds elapsed since this wisp was spawned.
  double age = 0;

  /// Total life span in seconds.
  final double life;

  /// Radius at spawn time, in logical pixels.
  final double initialSize;

  /// Phase offset applied to the horizontal-curl sine.
  final double phase;

  /// Peak horizontal sway amplitude, in logical pixels per second.
  final double drift;

  /// True once [age] has reached [life].
  bool get dead => age >= life;

  /// Normalized life progress in `[0, 1]`.
  double get t => (age / life).clamp(0.0, 1.0);

  /// Advances the wisp by [dt] seconds.
  void update(double dt) {
    age += dt;
    final curlVx = math.sin(age * 2.6 + phase) * drift;
    pos = Offset(pos.dx + curlVx * dt, pos.dy + vel.dy * dt);
    final dragFactor = math.pow(0.45, dt).toDouble();
    vel = Offset(vel.dx, vel.dy * dragFactor);
  }
}
