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

  /// Captured tel: URIs from the injected phone call launcher.
  late List<Uri> capturedCallUris;

  /// Stub phone call launcher that always succeeds.
  Future<bool> fakeCallLauncher(Uri uri) async {
    capturedCallUris.add(uri);
    return true;
  }

  /// Stub phone call launcher that always fails.
  Future<bool> failingCallLauncher(Uri uri) async {
    capturedCallUris.add(uri);
    return false;
  }

  /// Stub phone call launcher that throws.
  Future<bool> throwingCallLauncher(Uri uri) async {
    throw Exception('Platform channel error');
  }

  final primaryContact = const EmergencyContact(
    id: '1',
    name: 'Mom',
    phone: '+8801712345678',
    isPrimary: true,
  );

  final secondaryContact = const EmergencyContact(
    id: '2',
    name: 'Brother',
    phone: '+8801787654321',
  );

  final testContacts = [primaryContact, secondaryContact];

  final noPrimaryContacts = [
    const EmergencyContact(id: '3', name: 'Friend', phone: '+8801799999999'),
    const EmergencyContact(id: '4', name: 'Colleague', phone: '+8801788888888'),
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
    capturedCallUris = [];

    useCase = TriggerSosUseCase(
      smsService: mockSms,
      locationService: mockLocation,
      notificationService: mockNotification,
      phoneCallLauncher: fakeCallLauncher,
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

  // ── GROUP 1: Core SOS Flow ────────────────────────────────────────────────

  group('TriggerSosUseCase — Core Flow', () {
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

    test('execute with empty contacts skips SMS and call', () async {
      final result = await useCase.execute(contacts: []);

      verifyNever(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ));
      expect(result.smsSentCount, 0);
      expect(result.totalContacts, 0);
      expect(result.callInitiated, false);
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

  // ── GROUP 2: Auto-Call Primary Contact (Fix E) ────────────────────────────

  group('TriggerSosUseCase — Auto-Call Primary Contact', () {
    test(
      'GIVEN contacts with isPrimary=true, '
      'WHEN execute() runs, '
      'THEN tel: URI is launched for the primary contact',
      () async {
        final result = await useCase.execute(contacts: testContacts);

        expect(result.callInitiated, true);
        expect(capturedCallUris, hasLength(1));
        expect(
          capturedCallUris.first.toString(),
          'tel:+8801712345678', // Mom's number (primary)
        );
      },
    );

    test(
      'GIVEN no contact has isPrimary=true, '
      'WHEN execute() runs, '
      'THEN tel: URI is launched for the FIRST contact (fallback)',
      () async {
        final result = await useCase.execute(contacts: noPrimaryContacts);

        expect(result.callInitiated, true);
        expect(capturedCallUris, hasLength(1));
        expect(
          capturedCallUris.first.toString(),
          'tel:+8801799999999', // Friend's number (first in list)
        );
      },
    );

    test(
      'GIVEN primary contact exists, '
      'WHEN execute() runs, '
      'THEN SMS is sent BEFORE call is initiated (order matters)',
      () async {
        // Track ordering via side effects.
        final callOrder = <String>[];

        when(() => mockSms.sendEmergencySms(
              contacts: any(named: 'contacts'),
              userName: any(named: 'userName'),
            )).thenAnswer((_) async {
          callOrder.add('sms');
          return 2;
        });

        useCase = TriggerSosUseCase(
          smsService: mockSms,
          locationService: mockLocation,
          notificationService: mockNotification,
          phoneCallLauncher: (uri) async {
            callOrder.add('call');
            return true;
          },
        );

        await useCase.execute(contacts: testContacts);

        expect(callOrder, ['sms', 'call']);
      },
    );

    test(
      'GIVEN phone call launcher returns false, '
      'WHEN execute() runs, '
      'THEN callInitiated is false but SMS still delivered',
      () async {
        useCase = TriggerSosUseCase(
          smsService: mockSms,
          locationService: mockLocation,
          notificationService: mockNotification,
          phoneCallLauncher: failingCallLauncher,
        );

        final result = await useCase.execute(contacts: testContacts);

        expect(result.callInitiated, false);
        expect(result.smsSentCount, 2); // SMS still sent
        verify(() => mockSms.sendEmergencySms(
              contacts: any(named: 'contacts'),
              userName: any(named: 'userName'),
            )).called(1);
      },
    );

    test(
      'GIVEN phone call launcher throws, '
      'WHEN execute() runs, '
      'THEN callInitiated is false but SOS flow completes',
      () async {
        useCase = TriggerSosUseCase(
          smsService: mockSms,
          locationService: mockLocation,
          notificationService: mockNotification,
          phoneCallLauncher: throwingCallLauncher,
        );

        final result = await useCase.execute(contacts: testContacts);

        expect(result.callInitiated, false);
        expect(result.smsSentCount, 2); // SMS still sent
        verify(() => mockNotification.showSosNotification()).called(1);
      },
    );

    test(
      'GIVEN empty contacts, '
      'WHEN execute() runs, '
      'THEN phone call is NOT attempted',
      () async {
        final result = await useCase.execute(contacts: []);

        expect(result.callInitiated, false);
        expect(capturedCallUris, isEmpty);
      },
    );

    test(
      'GIVEN contact phone contains formatting characters, '
      'WHEN call is initiated, '
      'THEN phone number is cleaned (only digits and +)',
      () async {
        final formattedContacts = [
          const EmergencyContact(
            id: '5',
            name: 'Formatted',
            phone: '+880 171-234 5678',
            isPrimary: true,
          ),
        ];

        when(() => mockSms.sendEmergencySms(
              contacts: any(named: 'contacts'),
              userName: any(named: 'userName'),
            )).thenAnswer((_) async => 1);

        await useCase.execute(contacts: formattedContacts);

        expect(capturedCallUris, hasLength(1));
        expect(
          capturedCallUris.first.toString(),
          'tel:+8801712345678', // Spaces and dashes removed
        );
      },
    );

    test(
      'SosResult.callInitiated defaults to false for backward compatibility',
      () {
        const result = SosResult(
          smsSentCount: 1,
          totalContacts: 1,
          hasLocation: true,
          // callInitiated not specified — defaults to false
        );
        expect(result.callInitiated, false);
      },
    );
  });
}
