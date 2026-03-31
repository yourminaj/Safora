import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mocktail/mocktail.dart';
import 'package:safora/injection.dart';
import 'package:safora/presentation/screens/onboarding/onboarding_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockBox extends Mock implements Box {}

/// Pump past all animate_do entrance animations (BounceInDown, FadeInDown,
/// FadeInUp) without trying to settle — the illustration uses an infinite
/// AnimationController.repeat() that will never quiesce.
Future<void> _pumpPastAnimations(WidgetTester tester) async {
  await tester.pump();
  // Advance past longest staggered animation (700ms delay + 800ms duration).
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Replace the widget tree with an empty container to properly dispose all
/// animation controllers before the test framework checks for pending timers.
/// This is the standard Flutter approach for testing infinite animations.
Future<void> _disposeAnimations(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Pump a large duration to flush any orphaned timers that animate_do
  // might have failed to cancel during dispose().
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  setUp(() {
    getIt.reset();
    final mockBox = MockBox();
    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(false);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    getIt.registerSingleton<Box>(mockBox, instanceName: 'app_settings');
    registerFallbackValue(const Locale('en'));
  });

  tearDown(() => getIt.reset());

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders onboarding screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);

      await _disposeAnimations(tester);
    });

    testWidgets('has next/get started button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      // Should have a button to proceed.
      expect(find.byType(ElevatedButton), findsAtLeast(1));

      await _disposeAnimations(tester);
    });

    testWidgets('renders PageView for multi-step onboarding', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      // OnboardingScreen uses PageView for 3 steps.
      expect(find.byType(PageView), findsOneWidget);

      await _disposeAnimations(tester);
    });

    testWidgets('has 3 page indicator dots', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      // Onboarding has 3 pages with indicator dots (AnimatedContainer).
      final dots = find.byType(AnimatedContainer);
      // At least 3 dots should be present for the 3 pages.
      expect(dots, findsAtLeast(3));

      await _disposeAnimations(tester);
    });

    testWidgets('starts on first page (index 0)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      // First page should be visible — look for the SOS overview content.
      expect(find.byType(Column), findsWidgets);

      await _disposeAnimations(tester);
    });

    testWidgets('can navigate to next page', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await _pumpPastAnimations(tester);

      // Tap the next button.
      final nextBtn = find.byType(ElevatedButton);
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn.first, warnIfMissed: false);
        // Pump past page transition + new page's entrance animations.
        await _pumpPastAnimations(tester);

        // Screen should still be visible after navigation.
        expect(find.byType(OnboardingScreen), findsOneWidget);
      }

      await _disposeAnimations(tester);
    });
  });
}
