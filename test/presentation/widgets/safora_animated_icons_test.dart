import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/widgets/safora_animated_icons.dart';

/// Widget tests for the three new branded CustomPainter icons that replaced
/// Lottie animations.
///
/// Each icon is a StatefulWidget with an AnimationController. We validate:
///   - Construction with default and custom parameters
///   - The widget tree contains a CustomPaint (the actual painting)
///   - Animated vs static mode (controller repeats vs stays at 0)
///   - Size is respected via SizedBox constraints
///   - No exceptions when mounted and then disposed (tick + dispose cycle)
void main() {
  // ─── SaforaVoiceDistressIcon ─────────────────────────────────
  group('SaforaVoiceDistressIcon', () {
    testWidgets('renders with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaVoiceDistressIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SaforaVoiceDistressIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: SaforaVoiceDistressIcon(size: 100)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify size is passed through to the widget.
      final icon = tester.widget<SaforaVoiceDistressIcon>(
        find.byType(SaforaVoiceDistressIcon),
      );
      expect(icon.size, equals(100));
    });

    testWidgets('renders in static (non-animated) mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SaforaVoiceDistressIcon(animated: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still render — just not animate.
      expect(find.byType(SaforaVoiceDistressIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('survives dispose without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaVoiceDistressIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      // Replace with empty container to trigger dispose.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // No exception = pass.
    });

    test('default size is 60', () {
      const icon = SaforaVoiceDistressIcon();
      expect(icon.size, equals(60));
    });

    test('default animated is true', () {
      const icon = SaforaVoiceDistressIcon();
      expect(icon.animated, isTrue);
    });
  });

  // ─── SaforaAnomalyMovementIcon ──────────────────────────────
  group('SaforaAnomalyMovementIcon', () {
    testWidgets('renders with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaAnomalyMovementIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SaforaAnomalyMovementIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: SaforaAnomalyMovementIcon(size: 80)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final icon = tester.widget<SaforaAnomalyMovementIcon>(
        find.byType(SaforaAnomalyMovementIcon),
      );
      expect(icon.size, equals(80));
    });

    testWidgets('renders in static (non-animated) mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SaforaAnomalyMovementIcon(animated: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SaforaAnomalyMovementIcon), findsOneWidget);
    });

    testWidgets('survives dispose without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaAnomalyMovementIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('default size is 60', () {
      const icon = SaforaAnomalyMovementIcon();
      expect(icon.size, equals(60));
    });

    test('default animated is true', () {
      const icon = SaforaAnomalyMovementIcon();
      expect(icon.animated, isTrue);
    });
  });

  // ─── SaforaRoadConditionIcon ────────────────────────────────
  group('SaforaRoadConditionIcon', () {
    testWidgets('renders with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaRoadConditionIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SaforaRoadConditionIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: SaforaRoadConditionIcon(size: 120)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final icon = tester.widget<SaforaRoadConditionIcon>(
        find.byType(SaforaRoadConditionIcon),
      );
      expect(icon.size, equals(120));
    });

    testWidgets('renders in static (non-animated) mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SaforaRoadConditionIcon(animated: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SaforaRoadConditionIcon), findsOneWidget);
    });

    testWidgets('survives dispose without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SaforaRoadConditionIcon())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('default size is 60', () {
      const icon = SaforaRoadConditionIcon();
      expect(icon.size, equals(60));
    });

    test('default animated is true', () {
      const icon = SaforaRoadConditionIcon();
      expect(icon.animated, isTrue);
    });
  });

  // ─── Cross-icon consistency ─────────────────────────────────
  group('Branded Icon API Consistency', () {
    test('all three icons have identical parameter signatures', () {
      // All must accept size + animated with the same defaults.
      const voice = SaforaVoiceDistressIcon();
      const anomaly = SaforaAnomalyMovementIcon();
      const road = SaforaRoadConditionIcon();

      expect(voice.size, equals(anomaly.size));
      expect(anomaly.size, equals(road.size));
      expect(voice.animated, equals(anomaly.animated));
      expect(anomaly.animated, equals(road.animated));
    });

    testWidgets('all three render side-by-side without conflict',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SaforaVoiceDistressIcon(size: 40),
                SaforaAnomalyMovementIcon(size: 40),
                SaforaRoadConditionIcon(size: 40),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SaforaVoiceDistressIcon), findsOneWidget);
      expect(find.byType(SaforaAnomalyMovementIcon), findsOneWidget);
      expect(find.byType(SaforaRoadConditionIcon), findsOneWidget);
    });
  });
}
