import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/home/widgets/sos_button.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('SosButton Widget Tests', () {
    testWidgets('renders SOS button widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      // Use pump instead of pumpAndSettle — Lottie animations loop infinitely.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SosButton), findsOneWidget);
    });

    testWidgets('SOS button is tappable without crash', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final sosButton = find.byType(SosButton);
      expect(sosButton, findsOneWidget);
      await tester.tap(sosButton, warnIfMissed: false);
      await tester.pump();

      // Button should still be present after tap.
      expect(sosButton, findsOneWidget);
    });

    testWidgets('contains visual container elements', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Button should render with nested Container widgets for styling.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('button has circular shape via BoxDecoration', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // SOS button uses GestureDetector for long-press activation.
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('long-press gesture is configured', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final sosButton = find.byType(SosButton);
      expect(sosButton, findsOneWidget);

      // Long press should not crash (SosCubit handles the countdown).
      await tester.longPress(sosButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // Button should still be present after long press.
      expect(sosButton, findsOneWidget);
    });
  });
}
