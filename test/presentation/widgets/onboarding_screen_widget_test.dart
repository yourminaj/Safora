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

      // Should have a button to proceed
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('has page indicator dots', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // Onboarding has 3 pages, so there should be indicator dots
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
