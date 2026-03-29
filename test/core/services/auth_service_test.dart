import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safora/core/services/auth_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService authService;
  late MockUser mockUser;
  late MockUserCredential mockCredential;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCredential = MockUserCredential();
    authService = AuthService(firebaseAuth: mockAuth);
  });

  // ── Existing tests (kept for regression coverage) ─────────────────────────

  group('AuthService — sign in / sign up', () {
    test('isSignedIn returns true when user exists', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(authService.isSignedIn, true);
    });

    test('isSignedIn returns false when no user', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(authService.isSignedIn, false);
    });

    test('signIn calls signInWithEmailAndPassword', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('test@test.com');

      final result =
          await authService.signIn(email: 'test@test.com', password: 'pass');
      expect(result, mockUser);
    });

    test('signOut calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await authService.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  // ── New: Email Verification ────────────────────────────────────────────────

  group('AuthService — isEmailVerified', () {
    test('returns true when user.emailVerified is true', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(true);
      expect(authService.isEmailVerified, true);
    });

    test('returns false when user.emailVerified is false', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(false);
      expect(authService.isEmailVerified, false);
    });

    test('returns false when no user is signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(authService.isEmailVerified, false);
    });
  });

  group('AuthService — reloadUser', () {
    test('calls user.reload when signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.reload()).thenAnswer((_) async {});

      await authService.reloadUser();
      verify(() => mockUser.reload()).called(1);
    });

    test('silently does nothing when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      // Must not throw
      await expectLater(authService.reloadUser(), completes);
    });
  });

  group('AuthService — sendEmailVerification', () {
    test('calls user.sendEmailVerification when unverified user signed in',
        () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockUser.email).thenReturn('test@test.com');
      when(() => mockUser.sendEmailVerification())
          .thenAnswer((_) async {});

      await authService.sendEmailVerification();
      verify(() => mockUser.sendEmailVerification()).called(1);
    });

    test('skips sending when email is already verified', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(true);
      when(() => mockUser.email).thenReturn('verified@test.com');

      await authService.sendEmailVerification();
      // Must never call sendEmailVerification on an already-verified account.
      verifyNever(() => mockUser.sendEmailVerification());
    });

    test('silently exits when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      await expectLater(authService.sendEmailVerification(), completes);
    });

    test('rethrows FirebaseAuthException on failure', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockUser.email).thenReturn('fail@test.com');
      when(() => mockUser.sendEmailVerification()).thenThrow(
        FirebaseAuthException(code: 'too-many-requests'),
      );

      await expectLater(
        authService.sendEmailVerification(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
