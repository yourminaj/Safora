import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_logger.dart';

/// Wrapper around Firebase Authentication.
///
/// Provides sign-in, sign-up, sign-out, and auth state observation.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The currently signed-in user (null if signed out).
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Whether the currently signed-in user has verified their email.
  ///
  /// NOTE: Firebase caches the verification flag locally.  Always call
  /// [reloadUser] before reading this in a routing guard to ensure freshness.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Force-refreshes the Firebase [User] token so [isEmailVerified] is current.
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      AppLogger.warning('[Auth] reloadUser failed: $e');
    }
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.warning('[Auth] sendEmailVerification: no current user');
      return;
    }
    if (user.emailVerified) {
      AppLogger.info('[Auth] Email already verified — skipping send');
      return;
    }
    try {
      await user.sendEmailVerification();
      AppLogger.info('[Auth] Verification email sent to ${user.email}');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('[Auth] sendEmailVerification failed: ${e.code}');
      rethrow;
    }
  }

  /// Stream of auth state changes (sign-in / sign-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password.
  ///
  /// Returns the [User] on success, or throws [FirebaseAuthException].
  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name if provided.
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      AppLogger.info('[Auth] Sign up successful: ${credential.user?.email}');
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('[Auth] Sign up failed: ${e.code}');
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.info('[Auth] Sign in successful: ${credential.user?.email}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('[Auth] Sign in failed: ${e.code}');
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.info('[Auth] Signed out');
    } catch (e) {
      AppLogger.error('[Auth] Sign out failed: $e');
      rethrow;
    }
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('[Auth] Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('[Auth] Password reset failed: ${e.code}');
      rethrow;
    }
  }

  /// Delete the current user's account.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      AppLogger.info('[Auth] Account deleted');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('[Auth] Account deletion failed: ${e.code}');
      rethrow;
    }
  }
}
