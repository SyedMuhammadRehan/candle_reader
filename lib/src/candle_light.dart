import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'candle_light_controller.dart';
import 'candle_light_interaction.dart';
import 'gestures/two_finger_scale_recognizer.dart';
import 'models/smoke_particle.dart';
import 'painters/flame_painter.dart';
import 'painters/halo_painter.dart';
import 'painters/smoke_painter.dart';
import 'painters/spotlight_painter.dart';
import 'palette.dart';

/// Overlays an interactive candle-light effect on [child].
///
/// The candle dims everything around its position, follows the user's
/// finger with spring physics, resizes on pinch, extinguishes when the
/// pinch closes past [extinguishRadius] (emitting rising smoke), and
/// re-lights on tap or when the pinch re-opens past [relightRadius].
///
/// Gesture routing is controlled by [interaction]:
///
/// * [CandleLightInteraction.grab] — all gestures drive the candle.
/// * [CandleLightInteraction.twoFinger] — single-finger gestures pass
///   through to [child] so scrollables keep working; two-finger
///   gestures control the candle. Default.
/// * [CandleLightInteraction.controlled] — no gestures are consumed;
///   drive the candle via a [CandleLightController].
///
/// The widget can also be controlled programmatically — attach a
/// [CandleLightController] and write to [CandleLightController.position],
/// [CandleLightController.radius], [CandleLightController.blowOut] and
/// [CandleLightController.relight].
///
/// Respects `MediaQuery.disableAnimations` to honor platform reduced-motion
/// settings — flicker/sway are suppressed when enabled.
class CandleLight extends StatefulWidget {
  /// Creates a candle-light overlay.
  const CandleLight({
    super.key,
    required this.child,
    this.interaction = CandleLightInteraction.twoFinger,
    this.controller,
    this.initialRadius = 160,
    this.minRadius = 8,
    this.maxRadius = 560,
    this.extinguishRadius = 26,
    this.relightRadius = 70,
    this.initialPosition,
    this.dimColor = const Color(0xFF050505),
    this.warmTint,
    this.palette = FlamePalette.warm,
    this.enableHaptics = true,
    this.onExtinguished,
    this.onRelit,
    this.onPositionChanged,
    this.onRadiusChanged,
    this.semanticLabel = 'Candle reading light',
  }) : assert(
          interaction != CandleLightInteraction.controlled || controller != null,
          'CandleLightInteraction.controlled requires a non-null controller.',
        );

  /// The content the candle illuminates. Typically a scrollable or paged
  /// book view, an image, or a PDF — but any widget works.
  final Widget child;

  /// How the widget routes gestures between itself and [child].
  final CandleLightInteraction interaction;

  /// Optional external controller for reading / setting the candle's
  /// position, radius, and lit state. Required when [interaction] is
  /// [CandleLightInteraction.controlled].
  final CandleLightController? controller;

  /// Light-pool radius at mount, in logical pixels.
  final double initialRadius;

  /// Clamped lower bound of the pool radius while still lit.
  final double minRadius;

  /// Clamped upper bound of the pool radius.
  final double maxRadius;

  /// Pinch below this radius → the flame is extinguished and a burst of
  /// smoke rises.
  final double extinguishRadius;

  /// Pinch above this radius (while out) → the flame re-lights.
  final double relightRadius;

  /// Where to place the flame when the widget first lays out. Null means
  /// the middle of the widget's first-frame size.
  final Offset? initialPosition;

  /// Color painted outside the light pool.
  final Color dimColor;

  /// Warm tint blended additively inside the pool. When null, the tint
  /// follows [palette] (`palette.mid`) so the glow automatically matches
  /// the flame's color. Set explicitly to override.
  final Color? warmTint;

  /// Layered flame color scheme.
  ///
  /// Defaults to [FlamePalette.warm] (a classic candle). Pass one of
  /// the other presets ([FlamePalette.blue], [FlamePalette.green],
  /// [FlamePalette.red], [FlamePalette.violet]) or build your own
  /// with [FlamePalette.fromColor].
  final FlamePalette palette;

  /// When true, fires system haptics on blow-out / relight / double-tap.
  final bool enableHaptics;

  /// Called the moment the flame is blown out (by any mechanism: pinch,
  /// controller, etc.).
  final VoidCallback? onExtinguished;

  /// Called the moment the flame re-lights.
  final VoidCallback? onRelit;

  /// Called while the user is dragging the flame target.
  final ValueChanged<Offset>? onPositionChanged;

  /// Called while the user is pinching.
  final ValueChanged<double>? onRadiusChanged;

  /// Accessibility label announced by screen readers for the candle layer.
  final String semanticLabel;

  @override
  State<CandleLight> createState() => _CandleLightState();
}

class _CandleLightState extends State<CandleLight>
    with SingleTickerProviderStateMixin {
  Offset _target = Offset.zero;
  Offset _current = Offset.zero;
  Offset _velocity = Offset.zero;

  late double _radius = widget.initialRadius;
  late double _baseRadius = widget.initialRadius;

  double _flame = 1.0;
  double _flameTarget = 1.0;
  bool _out = false;

  final List<SmokeParticle> _smokes = <SmokeParticle>[];
  double _smokeEmitWindow = 0;
  double _smokeEmitCountdown = 0;
  final math.Random _rng = math.Random();

  late final Ticker _ticker;
  double _time = 0;
  Duration _last = Duration.zero;

  bool _positionInited = false;
  bool _reducedMotion = false;
  bool _ignoreControllerEcho = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(CandleLight old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _detachController(old.controller);
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _detachController(widget.controller);
    super.dispose();
  }

  void _attachController(CandleLightController? c) {
    if (c == null) return;
    c.addListener(_onControllerChanged);
    _radius = c.radius;
    _baseRadius = c.radius;
    if (!c.isLit) {
      _out = true;
      _flameTarget = 0;
      _flame = 0;
    }
    if (c.position != Offset.zero) {
      _target = c.position;
      _current = c.position;
    }
  }

  void _detachController(CandleLightController? c) {
    c?.removeListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_ignoreControllerEcho) return;
    final c = widget.controller!;
    _target = c.position;
    if (c.radius != _radius) {
      _radius = c.radius;
      _baseRadius = c.radius;
    }
    if (c.isLit && _out) {
      _relight(notifyController: false);
    } else if (!c.isLit && !_out) {
      _blowOut(notifyController: false);
    }
    _ensureTicking();
  }

  void _writeToController(void Function(CandleLightController c) f) {
    final c = widget.controller;
    if (c == null) return;
    _ignoreControllerEcho = true;
    f(c);
    _ignoreControllerEcho = false;
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.08) {
      _time += dt.clamp(0.0, 0.08);
      if (mounted) setState(() {});
      return;
    }

    const k = 240.0;
    const d = 24.0;
    final fx = (_target.dx - _current.dx) * k - _velocity.dx * d;
    final fy = (_target.dy - _current.dy) * k - _velocity.dy * d;
    _velocity = _velocity + Offset(fx * dt, fy * dt);
    _current = _current + _velocity * dt;

    _flame += (_flameTarget - _flame) * math.min(1.0, dt * 7.5);

    for (var i = _smokes.length - 1; i >= 0; i--) {
      _smokes[i].update(dt);
      if (_smokes[i].dead) _smokes.removeAt(i);
    }
    if (_smokeEmitWindow > 0) {
      _smokeEmitWindow -= dt;
      _smokeEmitCountdown -= dt;
      if (_smokeEmitCountdown <= 0) {
        _spawnSmoke(1);
        _smokeEmitCountdown = 0.045 + _rng.nextDouble() * 0.06;
      }
    }

    _time += _reducedMotion ? 0 : dt;
    if (mounted) setState(() {});

    // A lit flame keeps ticking so flicker/sway continue; with reduced
    // motion or extinguished we can stop once physics has truly settled.
    final flameIsLiveAnimation = !_out && !_reducedMotion;
    final crossfading = (_flame - _flameTarget).abs() >= 0.001;
    final springActive = _velocity.distanceSquared >= 0.01 ||
        (_target - _current).distanceSquared >= 0.01;
    final hasSmoke = _smokes.isNotEmpty || _smokeEmitWindow > 0;
    final settled = !flameIsLiveAnimation &&
        !crossfading &&
        !springActive &&
        !hasSmoke;
    if (settled) {
      _ticker.stop();
    }
  }

  void _spawnSmoke(int count) {
    for (var i = 0; i < count; i++) {
      _smokes.add(SmokeParticle(
        pos: _current + Offset((_rng.nextDouble() - 0.5) * 10, -6),
        vel: Offset(0, -(26 + _rng.nextDouble() * 28)),
        life: 1.7 + _rng.nextDouble() * 1.4,
        initialSize: 3.0 + _rng.nextDouble() * 3.5,
        phase: _rng.nextDouble() * math.pi * 2,
        drift: 18 + _rng.nextDouble() * 26,
      ));
    }
    if (_smokes.length > 120) {
      _smokes.removeRange(0, _smokes.length - 120);
    }
  }

  void _blowOut({bool notifyController = true}) {
    if (_out) return;
    _out = true;
    _flameTarget = 0;
    _spawnSmoke(7);
    _smokeEmitWindow = 1.1;
    _smokeEmitCountdown = 0.04;
    _haptic(HapticFeedback.heavyImpact);
    widget.onExtinguished?.call();
    if (notifyController) _writeToController((c) => c.blowOut());
    _ensureTicking();
  }

  void _relight({bool notifyController = true}) {
    if (!_out) return;
    _out = false;
    _flameTarget = 1;
    _smokeEmitWindow = 0;
    _haptic(HapticFeedback.mediumImpact);
    widget.onRelit?.call();
    if (notifyController) _writeToController((c) => c.relight());
    _ensureTicking();
  }

  void _haptic(Future<void> Function() f) {
    if (widget.enableHaptics) {
      // ignore: discarded_futures
      f();
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _baseRadius = _radius;
    _target = d.focalPoint;
    _ensureTicking();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    _target = d.focalPoint;
    widget.onPositionChanged?.call(d.focalPoint);
    _writeToController((c) => c.position = d.focalPoint);

    if ((d.scale - 1.0).abs() > 1e-6) {
      final next =
          (_baseRadius * d.scale).clamp(widget.minRadius, widget.maxRadius);
      if (next != _radius) {
        _radius = next;
        widget.onRadiusChanged?.call(next);
        _writeToController((c) => c.radius = next);
      }
      if (!_out && next <= widget.extinguishRadius) {
        _blowOut();
      } else if (_out && next >= widget.relightRadius) {
        _relight();
      }
    }
    _ensureTicking();
  }

  void _onTap() {
    if (_out) {
      _relight();
      if (_radius < widget.relightRadius) {
        _radius = widget.initialRadius;
      }
    }
  }

  void _onLongPressStart(LongPressStartDetails d) {
    _haptic(HapticFeedback.selectionClick);
    _target = d.globalPosition;
    widget.onPositionChanged?.call(d.globalPosition);
    _writeToController((c) => c.position = d.globalPosition);
    _ensureTicking();
  }

  void _onLongPressMove(LongPressMoveUpdateDetails d) {
    _target = d.globalPosition;
    widget.onPositionChanged?.call(d.globalPosition);
    _writeToController((c) => c.position = d.globalPosition);
    _ensureTicking();
  }

  @override
  Widget build(BuildContext context) {
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_positionInited) {
          _positionInited = true;
          final controllerPos = widget.controller?.position;
          final hasControllerPos =
              controllerPos != null && controllerPos != Offset.zero;
          final seed = widget.initialPosition ??
              (hasControllerPos ? controllerPos : null) ??
              Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.45);
          _current = seed;
          _target = seed;
          if (widget.controller != null && !hasControllerPos) {
            // Defer: notifying listeners during layout can trip external
            // setState-in-build assertions.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _writeToController((c) => c.position = seed);
            });
          }
          _ensureTicking();
        }

        final stack = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SpotlightPainter(
                    center: _current,
                    radius: _radius,
                    intensity: _flame,
                    time: _time,
                    dimColor: widget.dimColor,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HaloPainter(
                    center: _current,
                    radius: _radius,
                    intensity: _flame,
                    time: _time,
                    warm: widget.warmTint ?? widget.palette.mid,
                    inner: widget.palette.core,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: FlamePainter(
                    center: _current,
                    intensity: _flame,
                    time: _time,
                    extinguished: _out,
                    palette: widget.palette,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SmokePainter(
                    particles: _smokes,
                  ),
                ),
              ),
            ),
          ],
        );

        Widget withGestures;
        switch (widget.interaction) {
          case CandleLightInteraction.grab:
            withGestures = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onTap: _onTap,
              child: stack,
            );
          case CandleLightInteraction.twoFinger:
            withGestures = RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
                TwoFingerScaleGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        TwoFingerScaleGestureRecognizer>(
                  TwoFingerScaleGestureRecognizer.new,
                  (TwoFingerScaleGestureRecognizer r) {
                    r
                      ..onStart = _onScaleStart
                      ..onUpdate = _onScaleUpdate;
                  },
                ),
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer>(
                  LongPressGestureRecognizer.new,
                  (LongPressGestureRecognizer r) {
                    r
                      ..onLongPressStart = _onLongPressStart
                      ..onLongPressMoveUpdate = _onLongPressMove;
                  },
                ),
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  TapGestureRecognizer.new,
                  (TapGestureRecognizer r) {
                    r.onTap = _onTap;
                  },
                ),
              },
              child: stack,
            );
          case CandleLightInteraction.controlled:
            withGestures = stack;
        }

        return Semantics(
          label: widget.semanticLabel,
          container: true,
          child: withGestures,
        );
      },
    );
  }
}
