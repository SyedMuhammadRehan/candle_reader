import 'package:flutter/material.dart';

/// Color scheme for the layered flame.
///
/// A flame in [CandleLight] is drawn as four nested teardrop layers
/// (broad blurry halo → main body → bright inner heart → white-hot
/// core) plus a small wick ember. [FlamePalette] supplies the color
/// for each of those layers; the painter tints them with the flame's
/// live intensity and flicker on top.
///
/// Use a preset like [FlamePalette.warm] (the default), [blue],
/// [green], [red], or [violet] for stylized variants, or
/// [FlamePalette.fromColor] to derive a palette from any single
/// dominant hue.
///
/// ```dart
/// CandleLight(
///   palette: FlamePalette.blue,
///   child: myReader,
/// )
///
/// CandleLight(
///   palette: FlamePalette.fromColor(Colors.pinkAccent),
///   child: myReader,
/// )
/// ```
@immutable
class FlamePalette {
  /// Creates a palette with explicit colors for each flame layer.
  const FlamePalette({
    required this.outer,
    required this.mid,
    required this.inner,
    required this.core,
    required this.ember,
  });

  /// Derive a full palette from a single dominant color.
  ///
  /// The outer layer is [color] with a slight darken, the mid layer
  /// is [color] itself, the inner layer is lightened toward white,
  /// and the core is nearly white with a hint of [color]. The ember
  /// tracks [color].
  factory FlamePalette.fromColor(Color color) {
    return FlamePalette(
      outer: Color.lerp(color, Colors.black, 0.22)!,
      mid: color,
      inner: Color.lerp(color, Colors.white, 0.55)!,
      core: Color.lerp(color, Colors.white, 0.85)!,
      ember: color,
    );
  }

  /// The broad, blurry outer halo of the flame. Typically the most
  /// saturated color in the palette.
  final Color outer;

  /// The main body of the flame. Usually a step brighter / less
  /// saturated than [outer].
  final Color mid;

  /// The bright inner heart, sitting just inside [mid].
  final Color inner;

  /// The hot central point. The painter blends this toward pure
  /// white as flame intensity approaches 1.
  final Color core;

  /// The small glowing wick ember at the base of the flame, visible
  /// most clearly while the flame is being extinguished.
  final Color ember;

  /// Classic candle fire — warm orange fading to a white-hot heart.
  ///
  /// This is the default palette for [CandleLight].
  static const FlamePalette warm = FlamePalette(
    outer: Color(0xFFFF7028),
    mid: Color(0xFFFFA040),
    inner: Color(0xFFFFE088),
    core: Color(0xFFFFEFB8),
    ember: Color(0xFFFF5A10),
  );

  /// Cold fire — deep blue outer layers tapering into a pale
  /// cyan-white core.
  static const FlamePalette blue = FlamePalette(
    outer: Color(0xFF1E5FD6),
    mid: Color(0xFF3E88FF),
    inner: Color(0xFFA8D8FF),
    core: Color(0xFFE8F6FF),
    ember: Color(0xFF1E5FD6),
  );

  /// Witch fire — acidic green with a pale ghostly core.
  static const FlamePalette green = FlamePalette(
    outer: Color(0xFF1E8A2A),
    mid: Color(0xFF4FD46A),
    inner: Color(0xFFBFEFB0),
    core: Color(0xFFE8FFE0),
    ember: Color(0xFF3B8F30),
  );

  /// Demonic red — heavy reds bleeding into a warm cream core.
  static const FlamePalette red = FlamePalette(
    outer: Color(0xFFB8180A),
    mid: Color(0xFFFF3820),
    inner: Color(0xFFFFA088),
    core: Color(0xFFFFE8D8),
    ember: Color(0xFFB8180A),
  );

  /// Arcane — violet layers with a soft lilac heart.
  static const FlamePalette violet = FlamePalette(
    outer: Color(0xFF6A1FB8),
    mid: Color(0xFFA340FF),
    inner: Color(0xFFDAB0FF),
    core: Color(0xFFF4E8FF),
    ember: Color(0xFF6A1FB8),
  );

  /// Returns a copy of this palette with the given fields replaced.
  FlamePalette copyWith({
    Color? outer,
    Color? mid,
    Color? inner,
    Color? core,
    Color? ember,
  }) {
    return FlamePalette(
      outer: outer ?? this.outer,
      mid: mid ?? this.mid,
      inner: inner ?? this.inner,
      core: core ?? this.core,
      ember: ember ?? this.ember,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlamePalette &&
        other.outer == outer &&
        other.mid == mid &&
        other.inner == inner &&
        other.core == core &&
        other.ember == ember;
  }

  @override
  int get hashCode => Object.hash(outer, mid, inner, core, ember);
}
