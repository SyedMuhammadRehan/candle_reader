import 'package:flutter/gestures.dart';

/// A [ScaleGestureRecognizer] that declines to win the gesture arena until
/// a second pointer is down.
///
/// This lets single-finger drags fall through to any competing recognizer
/// (typically the vertical-drag recognizer owned by a scrollable ancestor
/// or descendant), while two-finger drags / pinches are claimed for scale
/// handling as usual.
///
/// It is the mechanism behind [CandleLightInteraction.twoFinger].
class TwoFingerScaleGestureRecognizer extends ScaleGestureRecognizer {
  /// Creates the recognizer.
  TwoFingerScaleGestureRecognizer({super.debugOwner, super.supportedDevices});

  int _activePointers = 0;
  bool _armed = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _activePointers += 1;
    if (_activePointers >= 2) {
      _armed = true;
    }
    super.addAllowedPointer(event);
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    super.handleNonAllowedPointer(event);
  }

  @override
  void acceptGesture(int pointer) {
    // Defer arena acceptance until a 2nd pointer arrives so single-finger
    // drags go to the scroll recognizer.
    if (_armed) {
      super.acceptGesture(pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _activePointers = 0;
    _armed = false;
    super.didStopTrackingLastPointer(pointer);
  }
}
