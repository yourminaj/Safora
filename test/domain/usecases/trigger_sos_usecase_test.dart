import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/core/services/sms_service.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';

class MockSmsService extends Mock implements SmsService {}

class MockLocationService extends Mock implements LocationService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late TriggerSosUseCase useCase;
  late MockSmsService mockSms;
  late MockLocationService mockLocation;
  late MockNotificationService mockNotification;

  final testContacts = [
    const EmergencyContact(
      id: '1',
      name: 'Mom',
      phone: '+8801712345678',
      isPrimary: true,
    ),
    const EmergencyContact(
      id: '2',
      name: 'Brother',
      phone: '+8801787654321',
    ),
  ];

  final testPosition = Position(
    latitude: 23.8103,
    longitude: 90.4125,
    timestamp: DateTime(2026, 3, 21),
    accuracy: 10.0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  setUp(() {
    mockSms = MockSmsService();
    mockLocation = MockLocationService();
    mockNotification = MockNotificationService();

    useCase = TriggerSosUseCase(
      smsService: mockSms,
      locationService: mockLocation,
      notificationService: mockNotification,
    );

    // Default stubs.
    when(() => mockLocation.getCurrentPosition())
        .thenAnswer((_) async => testPosition);
    when(() => mockLocation.lastPosition).thenReturn(testPosition);
    when(() => mockSms.sendEmergencySms(
          contacts: any(named: 'contacts'),
          userName: any(named: 'userName'),
        )).thenAnswer((_) async => 2);
    when(() => mockNotification.showSosNotification())
        .thenAnswer((_) async {});
    when(() => mockNotification.cancelSosNotification())
        .thenAnswer((_) async {});
  });

  group('TriggerSosUseCase', () {
    test('execute fetches GPS location before sending SMS', () async {
      await useCase.execute(contacts: testContacts);

      // Location must be fetched first.
      verifyInOrder([
        () => mockLocation.getCurrentPosition(),
        () => mockSms.sendEmergencySms(
              contacts: any(named: 'contacts'),
              userName: any(named: 'userName'),
            ),
      ]);
    });

    test('execute sends SMS to all contacts', () async {
      final result = await useCase.execute(
        contacts: testContacts,
        userName: 'Minhaj',
      );

      verify(() => mockSms.sendEmergencySms(
            contacts: testContacts,
            userName: 'Minhaj',
          )).called(1);
      expect(result.smsSentCount, 2);
      expect(result.totalContacts, 2);
      expect(result.allSent, true);
    });

    test('execute shows persistent notification', () async {
      await useCase.execute(contacts: testContacts);

      verify(() => mockNotification.showSosNotification()).called(1);
    });

    test('execute with empty contacts skips SMS', () async {
      final result = await useCase.execute(contacts: []);

      verifyNever(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ));
      expect(result.smsSentCount, 0);
      expect(result.totalContacts, 0);
    });

    test('execute reports hasLocation correctly', () async {
      final result = await useCase.execute(contacts: testContacts);
      expect(result.hasLocation, true);

      // Simulate no GPS.
      when(() => mockLocation.lastPosition).thenReturn(null);
      final result2 = await useCase.execute(contacts: testContacts);
      expect(result2.hasLocation, false);
    });

    test('execute reports partial SMS delivery', () async {
      when(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          )).thenAnswer((_) async => 1); // Only 1 of 2 sent

      final result = await useCase.execute(contacts: testContacts);

      expect(result.smsSentCount, 1);
      expect(result.totalContacts, 2);
      expect(result.allSent, false);
    });

    test('cancel dismisses SOS notification', () async {
      await useCase.cancel();

      verify(() => mockNotification.cancelSosNotification()).called(1);
    });
  });
}
