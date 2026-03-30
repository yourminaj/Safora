import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'app_logger.dart';

/// Service managing app-level lock via PIN and/or biometrics.
///
/// PIN is stored as SHA-256 hash in the Hive `app_settings` box.
/// Biometric authentication uses the `local_auth` package.
class AppLockService {
  AppLockService({
    required Box settingsBox,
    LocalAuthentication? localAuth,
  })  : _box = settingsBox,
        _localAuth = localAuth ?? LocalAuthentication();

  final Box _box;
  final LocalAuthentication _localAuth;

  static const String _keyLockEnabled = 'app_lock_enabled';
  static const String _keyPinHash = 'app_lock_pin_hash';
  static const String _keyBiometricEnabled = 'app_lock_biometric';

  /// Whether app lock is currently enabled.
  bool get isLockEnabled =>
      _box.get(_keyLockEnabled, defaultValue: false) as bool;

  /// Whether a PIN has been set.
  bool get hasPinSet => _box.get(_keyPinHash) != null;

  /// Whether biometric is enabled (user preference).
  bool get isBiometricEnabled =>
      _box.get(_keyBiometricEnabled, defaultValue: true) as bool;

  /// Hash a PIN using SHA-256.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Set a new 4-digit PIN.
  Future<void> setPin(String pin) async {
    assert(pin.length == 4, 'PIN must be exactly 4 digits');
    await _box.put(_keyPinHash, _hashPin(pin));
    AppLogger.info('[AppLock] PIN set successfully');
  }

  /// Verify a PIN against the stored hash.
  bool verifyPin(String pin) {
    final storedHash = _box.get(_keyPinHash) as String?;
    if (storedHash == null) return false;
    return _hashPin(pin) == storedHash;
  }

  /// Remove the stored PIN.
  Future<void> clearPin() async {
    await _box.delete(_keyPinHash);
    AppLogger.info('[AppLock] PIN cleared');
  }

  /// Enable app lock. PIN must be set first.
  Future<void> enableLock() async {
    if (!hasPinSet) {
      throw StateError('Cannot enable lock without setting a PIN first');
    }
    await _box.put(_keyLockEnabled, true);
    AppLogger.info('[AppLock] Lock enabled');
  }

  /// Disable app lock.
  Future<void> disableLock() async {
    await _box.put(_keyLockEnabled, false);
    AppLogger.info('[AppLock] Lock disabled');
  }

  /// Toggle biometric preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _box.put(_keyBiometricEnabled, enabled);
    AppLogger.info('[AppLock] Biometric ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      AppLogger.warning('[AppLock] Biometric check failed: $e');
      return false;
    }
  }

  /// Get available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.warning('[AppLock] Failed to get biometrics: $e');
      return [];
    }
  }

  /// Attempt biometric authentication.
  ///
  /// Returns `true` if authentication succeeded.
  Future<bool> authenticateWithBiometric({
    String reason = 'Authenticate to unlock Safora',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      AppLogger.error('[AppLock] Biometric auth failed: $e');
      return false;
    }
  }
}
