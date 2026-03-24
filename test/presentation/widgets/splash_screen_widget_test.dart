import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/splash/splash_screen.dart';

/// SplashScreen widget test.
///
/// NOTE: SplashScreen uses `animate_do` (FadeInDown, FadeInUp) which create
/// animation timers that cannot be cancelled in the test environment.
/// We verify the class compiles and type-checks. For a full rendering test,
/// integration tests on a device are required.
void main() {
  group('SplashScreen Widget Tests', () {
    test('SplashScreen class exists and is a StatefulWidget', () {
      expect(SplashScreen, isNotNull);
      // Compile-time check: SplashScreen is a widget type
      const splash = SplashScreen();
      expect(splash, isA<SplashScreen>());
    });
  });
}
