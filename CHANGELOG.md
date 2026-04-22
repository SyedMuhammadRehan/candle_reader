## 0.1.0

Initial release.

- `CandleLight` widget: spring-follow animated flame, warm spotlight with
  radial falloff, organic flicker, pinch to resize the light pool, pinch
  hard to blow the flame out with a rising smoke burst, tap to relight.
- `CandleLightController` for programmatic control of position, radius,
  and lit state.
- Three interaction modes: `grab`, `twoFinger` (default — single-finger
  gestures pass through to scrollable children), and `controlled`.
- Callbacks: `onExtinguished`, `onRelit`, `onPositionChanged`,
  `onRadiusChanged`.
- `FlamePalette` for flame color — presets (`warm`, `blue`, `green`,
  `red`, `violet`), a `fromColor(...)` factory, or a fully custom
  instance. The pool glow follows the palette unless `warmTint` is
  set explicitly.
- `twoFinger` mode now also accepts long-press-then-drag so a single
  finger can pick the candle up without waiting for a second finger,
  while normal single-finger gestures still scroll the child.
- Reduced-motion aware via `MediaQuery`.
- Screen-reader `Semantics` wrapper.
- Ticker auto-pauses when the candle is at rest and no smoke is in flight.
