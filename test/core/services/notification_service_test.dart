import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/notification_service.dart';

// NotificationService relies heavily on platform channels (FlutterLocalNotificationsPlugin,
// FirebaseMessaging, FirebaseAuth, Firestore). We test the public API contract
// and verify the service is instantiable without errors.

void main() {
  group('NotificationService', () {
    test('can be instantiated', () {
      final service = NotificationService();
      expect(service, isNotNull);
    });

    test('is not a singleton — each call creates a new instance', () {
      final a = NotificationService();
      final b = NotificationService();
      expect(identical(a, b), false);
    });
  });
}
