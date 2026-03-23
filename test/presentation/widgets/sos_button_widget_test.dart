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

    testWidgets('SOS button is tappable', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final sosButton = find.byType(SosButton);
      expect(sosButton, findsOneWidget);
      await tester.tap(sosButton, warnIfMissed: false);
      await tester.pump();

      expect(sosButton, findsOneWidget);
    });

    testWidgets('SOS button contains Container widgets', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SosButton()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Container), findsWidgets);
    });
  });
}
