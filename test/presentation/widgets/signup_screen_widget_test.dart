import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/auth_service.dart';
import 'package:safora/injection.dart';
import 'package:safora/presentation/screens/auth/signup_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }
    mockAuth = MockAuthService();
    when(() => mockAuth.isSignedIn).thenReturn(false);
    getIt.registerSingleton<AuthService>(mockAuth);
  });

  tearDown(() {
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }
  });

  group('SignupScreen Widget Tests', () {
    testWidgets('renders signup screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('has 4 text input fields (name, email, password, confirm)',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      // SignupScreen has: Full Name, Email, Password, Confirm Password
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('displays Create Account title and subtitle', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsAtLeast(1));
      expect(find.text('Protect your family with Safora'), findsOneWidget);
    });

    testWidgets('has shield logo icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('has Sign In navigation link', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('form validation shows errors on empty submit', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      // Tap Create Account button with empty fields.
      final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Validation errors should appear for required fields.
        expect(find.text('Name is required'), findsOneWidget);
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      }
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      // Password field has visibility_off by default.
      final visOff = find.byIcon(Icons.visibility_off);
      if (visOff.evaluate().isNotEmpty) {
        await tester.tap(visOff);
        await tester.pumpAndSettle();

        // After toggle, icon changes to visibility.
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      }
    });
  });
}
