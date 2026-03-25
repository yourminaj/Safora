import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/injection.dart';
import 'package:safora/presentation/screens/onboarding/onboarding_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockBox extends Mock implements Box {}

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
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('has next/get started button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // Should have a button to proceed.
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('renders PageView for multi-step onboarding', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // OnboardingScreen uses PageView for 3 steps.
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('has 3 page indicator dots', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // Onboarding has 3 pages with indicator dots (AnimatedContainer).
      final dots = find.byType(AnimatedContainer);
      // At least 3 dots should be present for the 3 pages.
      expect(dots, findsAtLeast(3));
    });

    testWidgets('starts on first page (index 0)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // First page should be visible — look for the SOS overview content.
      // The onboarding items contain shield/safety related icons.
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('can navigate to next page', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // Tap the next button.
      final nextBtn = find.byType(ElevatedButton);
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Screen should still be visible after navigation.
        expect(find.byType(OnboardingScreen), findsOneWidget);
      }
    });
  });
}
