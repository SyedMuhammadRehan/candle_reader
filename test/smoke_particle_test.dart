import 'dart:ui';

import 'package:candle_reader/src/models/smoke_particle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmokeParticle', () {
    test('dead is false before life elapses', () {
      final p = SmokeParticle(
        pos: Offset.zero,
        vel: const Offset(0, -30),
        life: 2,
        initialSize: 3,
        phase: 0,
        drift: 0,
      );
      p.update(0.5);
      expect(p.dead, isFalse);
      expect(p.t, closeTo(0.25, 1e-6));
    });

    test('dead is true once life has elapsed', () {
      final p = SmokeParticle(
        pos: Offset.zero,
        vel: const Offset(0, -30),
        life: 1,
        initialSize: 3,
        phase: 0,
        drift: 0,
      );
      p.update(1.1);
      expect(p.dead, isTrue);
    });

    test('rises (dy decreases) under a negative vertical velocity', () {
      final p = SmokeParticle(
        pos: const Offset(0, 100),
        vel: const Offset(0, -40),
        life: 2,
        initialSize: 3,
        phase: 0,
        drift: 0,
      );
      final startY = p.pos.dy;
      p.update(0.1);
      expect(p.pos.dy, lessThan(startY));
    });

    test('vertical velocity decays under drag', () {
      final p = SmokeParticle(
        pos: Offset.zero,
        vel: const Offset(0, -100),
        life: 5,
        initialSize: 3,
        phase: 0,
        drift: 0,
      );
      final before = p.vel.dy.abs();
      p.update(0.25);
      final after = p.vel.dy.abs();
      expect(after, lessThan(before));
    });

    test('drifts horizontally when drift > 0', () {
      final p = SmokeParticle(
        pos: Offset.zero,
        vel: const Offset(0, -30),
        life: 5,
        initialSize: 3,
        phase: 0,
        drift: 30,
      );
      p.update(0.15);
      expect(p.pos.dx, isNot(0));
    });
  });
}
