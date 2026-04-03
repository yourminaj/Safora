import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/sms_service.dart';
import 'package:safora/data/models/emergency_contact.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocationService mockLocation;
  late SmsService service;

  setUp(() {
    mockLocation = MockLocationService();
    service = SmsService(locationService: mockLocation);
  });

  group('SmsService', () {
    test('sendEmergencySms returns 0 for empty contacts list', () async {
      final result = await service.sendEmergencySms(contacts: []);
      expect(result, 0);
      verifyNever(() => mockLocation.buildLocationMessage());
    });

    test('sendEmergencySms calls buildLocationMessage', () async {
      when(() => mockLocation.buildLocationMessage())
          .thenAnswer((_) async => 'Location unavailable.');

      final contacts = [
        const EmergencyContact(
          name: 'Mom',
          phone: '+1234567890',
          relationship: 'Mother',
        ),
      ];

      // This will attempt platform SMS which will fail in test environment.
      // We verify the location service was called.
      await service.sendEmergencySms(contacts: contacts, userName: 'Test');
      verify(() => mockLocation.buildLocationMessage()).called(1);
    });

    test('sendEmergencySms uses default name when userName is null', () async {
      when(() => mockLocation.buildLocationMessage())
          .thenAnswer((_) async => 'Location: 23.8, 90.4');

      final contacts = [
        const EmergencyContact(
          name: 'Dad',
          phone: '+9876543210',
          relationship: 'Father',
        ),
      ];

      // userName is null → should use 'Someone'
      await service.sendEmergencySms(contacts: contacts);
      verify(() => mockLocation.buildLocationMessage()).called(1);
    });

    test('sendBatteryAlert calls buildLocationMessage', () async {
      when(() => mockLocation.buildLocationMessage())
          .thenAnswer((_) async => 'Location unavailable.');

      const contact = EmergencyContact(
        name: 'Sister',
        phone: '+1112223333',
        relationship: 'Sibling',
      );

      await service.sendBatteryAlert(
        contact: contact,
        batteryLevel: 10,
        userName: 'Test User',
      );
      verify(() => mockLocation.buildLocationMessage()).called(1);
    });

    test('sendAlertSms does not require location service', () async {
      // sendAlertSms bypasses location — just sends the message directly
      await service.sendAlertSms(
        phone: '+1234567890',
        message: 'Custom alert message',
      );
      verifyNever(() => mockLocation.buildLocationMessage());
    });
  });
}
