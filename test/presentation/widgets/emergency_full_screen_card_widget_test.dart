import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/presentation/screens/emergency/emergency_full_screen_card.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  late AlertEvent testAlert;

  setUp(() {
    testAlert = AlertEvent(
      id: 'test-alert-001',
      type: AlertType.earthquake,
      title: 'Earthquake Detected',
      description: 'A 6.2 magnitude earthquake has been detected nearby.',
      latitude: 23.8103,
      longitude: 90.4125,
      timestamp: DateTime(2026, 1, 15, 10, 30),
      riskScore: 95,
      distanceKm: 2.5,
    );
  });

  group('EmergencyFullScreenCard Widget Tests', () {
    testWidgets('renders emergency full screen card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EmergencyFullScreenCard), findsOneWidget);
    });

    testWidgets('displays alert title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Earthquake Detected'), findsOneWidget);
    });

    testWidgets('displays RISK SCORE text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('RISK SCORE: 95'), findsOneWidget);
    });

    testWidgets('renders I AM SAFE button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('I AM SAFE'), findsOneWidget);
    });

    testWidgets('prevents back button dismissal (canPop: false)',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PopScope), findsOneWidget);
    });

    testWidgets('renders warning icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byIcon(Icons.warning_amber_rounded),
        findsOneWidget,
      );
    });

    testWidgets('renders alert description', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: EmergencyFullScreenCard(alert: testAlert),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('A 6.2 magnitude earthquake has been detected nearby.'),
        findsOneWidget,
      );
    });
  });
}
