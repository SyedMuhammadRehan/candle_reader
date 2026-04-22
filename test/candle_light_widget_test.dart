import 'package:candle_reader/candle_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CandleLight renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CandleLight(
          child: Text('hello'),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  test('controlled mode asserts without a controller', () {
    expect(
      () => CandleLight(
        interaction: CandleLightInteraction.controlled,
        child: const Text('no controller'),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('controller.blowOut fires onExtinguished', (tester) async {
    final controller = CandleLightController();
    var extinguished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: CandleLight(
          controller: controller,
          interaction: CandleLightInteraction.controlled,
          onExtinguished: () => extinguished++,
          child: const Text('x'),
        ),
      ),
    );
    await tester.pump();
    controller.blowOut();
    // Two pumps: one for listener to fire, one for state to transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(extinguished, 1);
  });

  testWidgets('reduced-motion is respected (no crash)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: CandleLight(child: Text('rm')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('rm'), findsOneWidget);
  });
}
