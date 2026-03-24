import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/decoy_call_service.dart';
import 'package:safora/injection.dart';

class MockDecoyCallService extends Mock implements DecoyCallService {}

void main() {
  late MockDecoyCallService mockDecoy;

  setUp(() {
    // Only register if not already registered (avoids conflicts with
    // other test files that share the global GetIt singleton).
    if (getIt.isRegistered<DecoyCallService>()) {
      getIt.unregister<DecoyCallService>();
    }

    mockDecoy = MockDecoyCallService();

    when(() => mockDecoy.startRinging()).thenAnswer((_) async {});
    when(() => mockDecoy.stopRinging()).thenAnswer((_) async {});
    when(() => mockDecoy.callerName).thenReturn('Mom');
    when(() => mockDecoy.isRinging).thenReturn(true);

    getIt.registerSingleton<DecoyCallService>(mockDecoy);
  });

  tearDown(() {
    if (getIt.isRegistered<DecoyCallService>()) {
      getIt.unregister<DecoyCallService>();
    }
  });

  group('DecoyCallService Unit Tests', () {
    test('callerName returns configured name', () {
      expect(mockDecoy.callerName, 'Mom');
    });

    test('startRinging calls through', () async {
      await mockDecoy.startRinging();
      verify(() => mockDecoy.startRinging()).called(1);
    });

    test('stopRinging calls through', () async {
      await mockDecoy.stopRinging();
      verify(() => mockDecoy.stopRinging()).called(1);
    });

    test('isRinging returns true when ringing', () {
      expect(mockDecoy.isRinging, true);
    });

    test('DecoyCallService is registered in DI', () {
      expect(getIt.isRegistered<DecoyCallService>(), true);
      expect(getIt<DecoyCallService>(), isA<DecoyCallService>());
    });
  });
}
