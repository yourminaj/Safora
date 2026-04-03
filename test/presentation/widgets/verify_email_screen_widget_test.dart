import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/auth_service.dart';
import 'package:safora/presentation/screens/auth/verify_email_screen.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService mockAuth;

  setUp(() {
    final getIt = GetIt.instance;
    // Reset to ensure clean state for each test.
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }
    mockAuth = _MockAuthService();
    when(() => mockAuth.isSignedIn).thenReturn(true);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.isEmailVerified).thenReturn(false);
    when(() => mockAuth.reloadUser()).thenAnswer((_) async {});
    when(() => mockAuth.sendEmailVerification()).thenAnswer((_) async {});
    when(() => mockAuth.signOut()).thenAnswer((_) async {});
    getIt.registerSingleton<AuthService>(mockAuth);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }
  });

  group('VerifyEmailScreen Widget Tests', () {
    testWidgets('renders verify email screen UI', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);
    });

    testWidgets('displays auto-check indicator text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Checking automatically every 5 seconds…'),
        findsOneWidget,
      );
    });

    testWidgets('renders resend verification email button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Resend Verification Email'), findsOneWidget);
    });

    testWidgets('renders sign out link', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Sign in with a different account'),
        findsOneWidget,
      );
    });

    testWidgets('renders email icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byIcon(Icons.mark_email_unread_rounded),
        findsOneWidget,
      );
    });

    testWidgets('tapping resend button calls sendEmailVerification',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const VerifyEmailScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Resend Verification Email'));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockAuth.sendEmailVerification()).called(1);
    });
  });
}
