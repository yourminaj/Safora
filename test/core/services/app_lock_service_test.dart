import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/app_lock_service.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}
class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockBox;
  late MockLocalAuth mockLocalAuth;
  late AppLockService service;

  setUp(() {
    mockBox = MockBox();
    mockLocalAuth = MockLocalAuth();
    service = AppLockService(
      settingsBox: mockBox,
      localAuth: mockLocalAuth,
    );
  });

  group('AppLockService — PIN Management', () {
    test('hasPinSet returns false when no PIN stored', () {
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn(null);
      expect(service.hasPinSet, false);
    });

    test('setPin stores SHA-256 hash', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await service.setPin('1234');
      final expectedHash =
          sha256.convert(utf8.encode('1234')).toString();
      verify(() => mockBox.put('app_lock_pin_hash', expectedHash)).called(1);
    });

    test('verifyPin returns true for correct PIN', () {
      final hash = sha256.convert(utf8.encode('5678')).toString();
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn(hash);
      expect(service.verifyPin('5678'), true);
    });

    test('verifyPin returns false for wrong PIN', () {
      final hash = sha256.convert(utf8.encode('5678')).toString();
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn(hash);
      expect(service.verifyPin('0000'), false);
    });

    test('verifyPin returns false when no PIN stored', () {
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn(null);
      expect(service.verifyPin('1234'), false);
    });

    test('clearPin deletes PIN hash', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      await service.clearPin();
      verify(() => mockBox.delete('app_lock_pin_hash')).called(1);
    });
  });

  group('AppLockService — Lock Toggle', () {
    test('isLockEnabled returns false by default', () {
      when(() => mockBox.get('app_lock_enabled', defaultValue: false))
          .thenReturn(false);
      expect(service.isLockEnabled, false);
    });

    test('enableLock sets flag to true', () async {
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn('somehash');
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await service.enableLock();
      verify(() => mockBox.put('app_lock_enabled', true)).called(1);
    });

    test('enableLock throws if no PIN set', () {
      when(() => mockBox.get('app_lock_pin_hash')).thenReturn(null);
      expect(() => service.enableLock(), throwsStateError);
    });

    test('disableLock sets flag to false', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await service.disableLock();
      verify(() => mockBox.put('app_lock_enabled', false)).called(1);
    });
  });

  group('AppLockService — Biometrics', () {
    test('isBiometricAvailable checks both capabilities', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) async => true);
      when(() => mockLocalAuth.isDeviceSupported())
          .thenAnswer((_) async => true);
      expect(await service.isBiometricAvailable(), true);
    });

    test('isBiometricAvailable returns false when not supported', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) async => true);
      when(() => mockLocalAuth.isDeviceSupported())
          .thenAnswer((_) async => false);
      expect(await service.isBiometricAvailable(), false);
    });

    test('isBiometricAvailable returns false on exception', () async {
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenThrow(Exception('platform error'));
      expect(await service.isBiometricAvailable(), false);
    });

    test('authenticateWithBiometric delegates to localAuth', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => true);
      final result = await service.authenticateWithBiometric();
      expect(result, true);
    });

    test('authenticateWithBiometric returns false on failure', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenThrow(Exception('auth error'));
      final result = await service.authenticateWithBiometric();
      expect(result, false);
    });

    test('getAvailableBiometrics returns list', () async {
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      final result = await service.getAvailableBiometrics();
      expect(result, [BiometricType.fingerprint]);
    });

    test('getAvailableBiometrics returns empty on error', () async {
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenThrow(Exception('error'));
      final result = await service.getAvailableBiometrics();
      expect(result, isEmpty);
    });
  });

  group('AppLockService — Biometric Preference', () {
    test('isBiometricEnabled defaults to true', () {
      when(() => mockBox.get('app_lock_biometric', defaultValue: true))
          .thenReturn(true);
      expect(service.isBiometricEnabled, true);
    });

    test('setBiometricEnabled persists preference', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await service.setBiometricEnabled(false);
      verify(() => mockBox.put('app_lock_biometric', false)).called(1);
    });
  });
}
