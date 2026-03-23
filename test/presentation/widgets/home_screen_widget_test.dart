import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/home/home_screen.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('renders HomeScreen widget tree', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const HomeScreen()),
      );
      // Use pump — Lottie shield_pulse animation loops infinitely.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('renders app title "Safora"', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Safora'), findsOneWidget);
    });

    testWidgets('renders status banner with gradient', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Safe state: "All Safe" text.
      expect(find.textContaining('Safe'), findsWidgets);
    });

    testWidgets('renders LIVE badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('renders notification and settings icons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
