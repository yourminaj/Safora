import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/app_lock_service.dart';
import 'package:safora/injection.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockLockService;

  setUp(() {
    if (getIt.isRegistered<AppLockService>()) {
      getIt.unregister<AppLockService>();
    }
    mockLockService = MockAppLockService();
    getIt.registerSingleton<AppLockService>(mockLockService);
  });

  tearDown(() {
    if (getIt.isRegistered<AppLockService>()) {
      getIt.unregister<AppLockService>();
    }
  });

  group('AppLockService DI Tests', () {
    test('AppLockService is registered in getIt', () {
      expect(getIt.isRegistered<AppLockService>(), true);
    });

    test('getIt resolves AppLockService instance', () {
      expect(getIt<AppLockService>(), isA<AppLockService>());
    });

    test('verifyPin delegates correctly', () {
      when(() => mockLockService.verifyPin('1234')).thenReturn(true);
      expect(getIt<AppLockService>().verifyPin('1234'), true);
    });

    test('isLockEnabled reads from service', () {
      when(() => mockLockService.isLockEnabled).thenReturn(false);
      expect(getIt<AppLockService>().isLockEnabled, false);
    });

    test('isBiometricAvailable checks device', () async {
      when(() => mockLockService.isBiometricAvailable())
          .thenAnswer((_) async => false);
      final result = await getIt<AppLockService>().isBiometricAvailable();
      expect(result, false);
    });
  });
}
