import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safora/core/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService authService;
  late MockUserCredential mockCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = AuthService(firebaseAuth: mockAuth);
    mockCredential = MockUserCredential();
    mockUser = MockUser();
  });

  group('AuthService', () {
    test('isSignedIn returns true when user exists', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(authService.isSignedIn, true);
    });

    test('isSignedIn returns false when no user', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(authService.isSignedIn, false);
    });

    test('currentUser returns User from FirebaseAuth', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(authService.currentUser, mockUser);
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
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@test.com',
            password: 'pass',
          )).called(1);
    });

    test('signUp calls createUserWithEmailAndPassword', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('new@test.com');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result =
          await authService.signUp(email: 'new@test.com', password: 'pass123');
      expect(result, mockUser);
    });

    test('signUp sets displayName when provided', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('new@test.com');
      when(() => mockUser.updateDisplayName(any()))
          .thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await authService.signUp(
          email: 'new@test.com', password: 'pass', displayName: 'John');
      verify(() => mockUser.updateDisplayName('John')).called(1);
    });

    test('signOut calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await authService.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });

    test('resetPassword calls sendPasswordResetEmail', () async {
      when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});
      await authService.resetPassword('test@test.com');
      verify(() => mockAuth.sendPasswordResetEmail(email: 'test@test.com'))
          .called(1);
    });

    test('deleteAccount calls currentUser.delete', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.delete()).thenAnswer((_) async {});
      await authService.deleteAccount();
      verify(() => mockUser.delete()).called(1);
    });

    test('authStateChanges returns stream from FirebaseAuth', () {
      final stream = Stream<User?>.value(mockUser);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => stream);
      expect(authService.authStateChanges, stream);
    });
  });
}
