/// Controls how [CandleLight] routes touch gestures between itself and its
/// child subtree.
///
/// See also:
///
///  * [CandleLight.interaction], the parameter this value is passed to.
///  * [CandleLightController], which is required by
///    [CandleLightInteraction.controlled] and optional for the others.
enum CandleLightInteraction {
  /// All gestures (pan, pinch, tap, double-tap) drive the candle. The child
  /// receives no gestures.
  ///
  /// Use when nothing beneath the candle needs to scroll or respond to
  /// touch — e.g. a single page of text.
  grab,

  /// One-finger gestures pass through to the child so a [ListView],
  /// [PageView], PDF viewer, or any scrollable widget underneath behaves
  /// normally. Two-finger drag moves the candle, two-finger pinch
  /// resizes the light pool, tap relights an extinguished candle, and
  /// long-press-then-drag lets a single finger pick the flame up and
  /// move it — the iOS reorder-to-pick-up model.
  ///
  /// This is the default and matches the iOS photo / map pinch-and-scroll
  /// model that most users already know.
  twoFinger,

  /// The widget consumes no gestures. The candle is driven entirely by a
  /// [CandleLightController] — useful when the host app has its own input
  /// model (keyboard, trackpad, eye-tracking, TTS sync, etc.).
  ///
  /// A non-null controller must be supplied.
  controlled,
}
