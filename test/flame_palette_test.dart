import 'package:candle_reader/candle_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlamePalette', () {
    test('constructor holds all five fields', () {
      const p = FlamePalette(
        outer: Color(0xFF111111),
        mid: Color(0xFF222222),
        inner: Color(0xFF333333),
        core: Color(0xFF444444),
        ember: Color(0xFF555555),
      );
      expect(p.outer, const Color(0xFF111111));
      expect(p.mid, const Color(0xFF222222));
      expect(p.inner, const Color(0xFF333333));
      expect(p.core, const Color(0xFF444444));
      expect(p.ember, const Color(0xFF555555));
    });

    test('presets are distinct from each other', () {
      expect(FlamePalette.warm, isNot(FlamePalette.blue));
      expect(FlamePalette.warm, isNot(FlamePalette.green));
      expect(FlamePalette.warm, isNot(FlamePalette.red));
      expect(FlamePalette.warm, isNot(FlamePalette.violet));
      expect(FlamePalette.blue, isNot(FlamePalette.green));
    });

    test('equality is value-based (separate instances compare equal)', () {
      final a = FlamePalette.warm.copyWith();
      final b = FlamePalette.warm.copyWith();
      expect(a == b, isTrue);
      expect(identical(a, b), isFalse);
    });

    test('hashCode is consistent with ==', () {
      expect(FlamePalette.warm.hashCode, FlamePalette.warm.hashCode);
      expect(
        FlamePalette.warm.hashCode,
        isNot(FlamePalette.blue.hashCode),
      );
    });

    test('identical() on a const preset is true (const canonicalization)', () {
      expect(identical(FlamePalette.warm, FlamePalette.warm), isTrue);
    });

    test('fromColor fills every layer', () {
      final p = FlamePalette.fromColor(Colors.pinkAccent);
      expect(p.ember, Colors.pinkAccent);
      expect(p.mid, Colors.pinkAccent);
      expect(p.outer, isNot(Colors.pinkAccent));
      expect(p.inner, isNot(Colors.pinkAccent));
      expect(p.core, isNot(Colors.pinkAccent));
    });

    test('fromColor: layers step from darker to lighter', () {
      final p = FlamePalette.fromColor(const Color(0xFF2080FF));
      double lum(Color c) => c.r * 0.299 + c.g * 0.587 + c.b * 0.114;
      expect(lum(p.outer), lessThan(lum(p.mid)));
      expect(lum(p.inner), greaterThan(lum(p.mid)));
      expect(lum(p.core), greaterThan(lum(p.inner)));
    });

    test('copyWith replaces only the given fields', () {
      final p = FlamePalette.warm.copyWith(ember: const Color(0xFF000000));
      expect(p.ember, const Color(0xFF000000));
      expect(p.outer, FlamePalette.warm.outer);
      expect(p.mid, FlamePalette.warm.mid);
      expect(p.inner, FlamePalette.warm.inner);
      expect(p.core, FlamePalette.warm.core);
    });

    test('copyWith with no args returns an equal palette', () {
      final p = FlamePalette.blue.copyWith();
      expect(p, FlamePalette.blue);
    });
  });
}
