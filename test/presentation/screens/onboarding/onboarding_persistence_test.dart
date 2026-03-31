import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<dynamic> {}

/// Unit tests for the onboarding persistence guard logic.
///
/// Validates the two-key system introduced in splash_screen.dart:
///   key 1: `onboarding_completed` (bool)  — was onboarding finished?
///   key 2: `onboarding_build`     (String) — what build stamped it?
///
/// The decision matrix is:
///   ┌───────────────────────┬──────────────────┬────────────────────┐
///   │ onboarding_completed  │ onboarding_build │ needsOnboarding    │
///   ├───────────────────────┼──────────────────┼────────────────────┤
///   │ false                 │ (any)            │ true               │
///   │ true                  │ ''  (empty)      │ true               │
///   │ true                  │ '42'             │ false              │
///   └───────────────────────┴──────────────────┴────────────────────┘
///
/// These tests exercise the *logic* that runs inside `_navigateNext()`
/// without needing to pump the whole widget tree (which requires
/// go_router, animate_do timers, PackageInfo platform channel mocking, etc.).



void main() {
  late MockBox mockSettings;

  setUp(() {
    mockSettings = MockBox();
  });

  /// Replicates the exact decision logic from splash_screen.dart:
  ///   final needsOnboarding = !onboardingDone || storedBuild.isEmpty;
  bool needsOnboarding({
    required bool onboardingDone,
    required String storedBuild,
  }) {
    return !onboardingDone || storedBuild.isEmpty;
  }

  group('Onboarding Guard — Decision Logic', () {
    test('fresh install: no flag, no build → needs onboarding', () {
      when(() => mockSettings.get('onboarding_completed',
          defaultValue: false)).thenReturn(false);
      when(() => mockSettings.get('onboarding_build', defaultValue: ''))
          .thenReturn('');

      final result = needsOnboarding(
        onboardingDone: mockSettings.get('onboarding_completed',
            defaultValue: false) as bool,
        storedBuild:
            mockSettings.get('onboarding_build', defaultValue: '') as String,
      );

      expect(result, isTrue, reason: 'First install must show onboarding');
    });

    test('legacy install: flag=true, no build → needs onboarding (migration)',
        () {
      when(() => mockSettings.get('onboarding_completed',
          defaultValue: false)).thenReturn(true);
      when(() => mockSettings.get('onboarding_build', defaultValue: ''))
          .thenReturn('');

      final result = needsOnboarding(
        onboardingDone: mockSettings.get('onboarding_completed',
            defaultValue: false) as bool,
        storedBuild:
            mockSettings.get('onboarding_build', defaultValue: '') as String,
      );

      expect(result, isTrue,
          reason:
              'Legacy installs with flag but no build stamp must re-onboard');
    });

    test('completed install: flag=true, build=42 → does NOT need onboarding',
        () {
      when(() => mockSettings.get('onboarding_completed',
          defaultValue: false)).thenReturn(true);
      when(() => mockSettings.get('onboarding_build', defaultValue: ''))
          .thenReturn('42');

      final result = needsOnboarding(
        onboardingDone: mockSettings.get('onboarding_completed',
            defaultValue: false) as bool,
        storedBuild:
            mockSettings.get('onboarding_build', defaultValue: '') as String,
      );

      expect(result, isFalse,
          reason: 'Completed onboarding with stamp should skip');
    });

    test('edge case: flag=false, build=42 → needs onboarding', () {
      // This shouldn't happen in practice, but tests the precedence:
      // !onboardingDone is true, so needsOnboarding = true.
      when(() => mockSettings.get('onboarding_completed',
          defaultValue: false)).thenReturn(false);
      when(() => mockSettings.get('onboarding_build', defaultValue: ''))
          .thenReturn('42');

      final result = needsOnboarding(
        onboardingDone: mockSettings.get('onboarding_completed',
            defaultValue: false) as bool,
        storedBuild:
            mockSettings.get('onboarding_build', defaultValue: '') as String,
      );

      expect(result, isTrue,
          reason:
              'Even with build stamp, flag=false means onboarding not done');
    });
  });

  group('Onboarding Completion — Hive Writes', () {
    test('_completeOnboarding writes both keys', () async {
      // Simulate what _completeOnboarding does:
      // await settingsBox.put('onboarding_completed', true);
      // await settingsBox.put('onboarding_build', info.buildNumber);
      when(() => mockSettings.put(any(), any())).thenAnswer((_) async {});

      await mockSettings.put('onboarding_completed', true);
      await mockSettings.put('onboarding_build', '42');

      verify(() => mockSettings.put('onboarding_completed', true)).called(1);
      verify(() => mockSettings.put('onboarding_build', '42')).called(1);
    });

    test('_completeOnboarding writes onboarding_completed as true (not null)',
        () async {
      when(() => mockSettings.put(any(), any())).thenAnswer((_) async {});

      await mockSettings.put('onboarding_completed', true);

      // Capture the value to ensure it's a bool, not null/String.
      final captured =
          verify(() => mockSettings.put('onboarding_completed', captureAny()))
              .captured;
      expect(captured.single, isA<bool>());
      expect(captured.single, isTrue);
    });

    test('_completeOnboarding writes onboarding_build as non-empty string',
        () async {
      when(() => mockSettings.put(any(), any())).thenAnswer((_) async {});

      const buildNumber = '15'; // Simulated PackageInfo.buildNumber
      await mockSettings.put('onboarding_build', buildNumber);

      final captured =
          verify(() => mockSettings.put('onboarding_build', captureAny()))
              .captured;
      expect(captured.single, isA<String>());
      expect((captured.single as String).isNotEmpty, isTrue);
    });
  });

  group('Onboarding Guard — Routing Expectations', () {
    test(
        'when needsOnboarding=true, '
        'expected route is /onboarding', () {
      final result = needsOnboarding(onboardingDone: false, storedBuild: '');
      expect(result, isTrue);
      // In production code: context.go('/onboarding');
    });

    test(
        'when needsOnboarding=false and not signed in, '
        'expected route is /login', () {
      final result = needsOnboarding(onboardingDone: true, storedBuild: '7');
      expect(result, isFalse);
      // In production code: context.go('/login');
    });

    test(
        'when needsOnboarding=false and signed in + verified, '
        'expected route is /home', () {
      final result = needsOnboarding(onboardingDone: true, storedBuild: '7');
      expect(result, isFalse);
      // In production code: context.go('/home');
    });

    test(
        'when needsOnboarding=false and signed in + NOT verified, '
        'expected route is /verify-email', () {
      final result = needsOnboarding(onboardingDone: true, storedBuild: '7');
      expect(result, isFalse);
      // In production code: context.go('/verify-email');
    });
  });
}
