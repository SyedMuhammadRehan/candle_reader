import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Drives a [CandleLight] from outside its subtree.
///
/// Pass a controller to `CandleLight.controller` and then update its fields
/// or call its methods to command the flame. The widget animates to the
/// new state (spring physics for [position], cross-fade for ignite /
/// extinguish, instant for [radius]).
///
/// When the user interacts with the widget in
/// [CandleLightInteraction.grab] or [CandleLightInteraction.twoFinger]
/// mode, the controller is kept in sync so external listeners observe the
/// live target.
///
/// ```dart
/// final controller = CandleLightController();
///
/// CandleLight(
///   controller: controller,
///   child: myReader,
/// );
///
/// // Move the flame to a specific word:
/// controller.position = wordRect.center;
///
/// // Blow out when the screen dims:
/// controller.blowOut();
/// ```
class CandleLightController extends ChangeNotifier {
  /// Creates a controller with the given initial target state.
  CandleLightController({
    Offset? initialPosition,
    double initialRadius = 160,
    bool initiallyLit = true,
  })  : _position = initialPosition ?? Offset.zero,
        _radius = initialRadius,
        _lit = initiallyLit;

  Offset _position;
  double _radius;
  bool _lit;

  /// Target position for the flame. Writing a new value causes the widget
  /// to spring-animate toward it.
  Offset get position => _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    notifyListeners();
  }

  /// Target radius of the light pool, in logical pixels. Writing a new
  /// value applies instantly (no ease) — if you want an animated resize,
  /// drive [radius] yourself with a `Tween` or `AnimationController`.
  double get radius => _radius;
  set radius(double value) {
    if (_radius == value) return;
    _radius = value;
    notifyListeners();
  }

  /// Whether the candle is currently burning.
  ///
  /// Read-only. Mutate via [blowOut] / [relight].
  bool get isLit => _lit;

  /// Extinguishes the flame. Emits a smoke burst in the widget. No-op if
  /// already out.
  void blowOut() {
    if (!_lit) return;
    _lit = false;
    notifyListeners();
  }

  /// Re-ignites the flame. No-op if already lit.
  void relight() {
    if (_lit) return;
    _lit = true;
    notifyListeners();
  }
}
