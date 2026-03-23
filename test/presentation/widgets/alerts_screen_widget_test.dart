import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/alerts/alerts_screen.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AlertsScreen Widget Tests', () {
    testWidgets('renders Alerts title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const AlertsScreen()),
      );
      await tester.pumpAndSettle();

      // AppBar title should display localized "Alerts".
      expect(find.text('Disaster Alerts'), findsOneWidget);
    });

    testWidgets('renders filter chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const AlertsScreen()),
      );
      await tester.pumpAndSettle();

      // Filter chips should be present ("All" should be initially selected).
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('refresh button is present in AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const AlertsScreen()),
      );
      await tester.pumpAndSettle();

      // Refresh icon should be in AppBar.
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('shows alert count badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const AlertsScreen()),
      );
      await tester.pumpAndSettle();

      // With empty alerts, should show "0 Alerts" or similar.
      expect(find.textContaining('0'), findsWidgets);
    });
  });
}
