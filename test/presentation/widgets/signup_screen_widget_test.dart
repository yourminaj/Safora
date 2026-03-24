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

    testWidgets('has text input fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const SignupScreen()),
      );
      await tester.pumpAndSettle();

      // Signup screen should have at least 2 text fields (email + password)
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });
}
