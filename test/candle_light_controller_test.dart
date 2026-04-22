import 'dart:ui';

import 'package:candle_reader/candle_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandleLightController', () {
    test('holds the values passed to the constructor', () {
      final c = CandleLightController(
        initialPosition: const Offset(12, 34),
        initialRadius: 200,
        initiallyLit: false,
      );
      expect(c.position, const Offset(12, 34));
      expect(c.radius, 200);
      expect(c.isLit, isFalse);
    });

    test('setting position notifies listeners only on change', () {
      final c = CandleLightController(initialPosition: Offset.zero);
      var calls = 0;
      c.addListener(() => calls++);

      c.position = const Offset(1, 1);
      c.position = const Offset(1, 1);
      c.position = const Offset(2, 2);

      expect(calls, 2);
      expect(c.position, const Offset(2, 2));
    });

    test('radius set notifies on change only', () {
      final c = CandleLightController(initialRadius: 100);
      var calls = 0;
      c.addListener(() => calls++);

      c.radius = 100;
      c.radius = 250;
      c.radius = 250;
      c.radius = 50;

      expect(calls, 2);
    });

    test('blowOut / relight flip isLit and notify', () {
      final c = CandleLightController();
      var calls = 0;
      c.addListener(() => calls++);

      expect(c.isLit, isTrue);
      c.blowOut();
      expect(c.isLit, isFalse);
      c.blowOut();
      c.relight();
      expect(c.isLit, isTrue);
      c.relight();

      expect(calls, 2);
    });
  });
}
