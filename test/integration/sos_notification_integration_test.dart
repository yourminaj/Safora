import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/core/services/sms_service.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/connectivity_service.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:geolocator/geolocator.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockSmsService extends Mock implements SmsService {}
class MockAudioService extends Mock implements AudioService {}
class MockLocationService extends Mock implements LocationService {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}
class MockBox extends Mock implements Box<dynamic> {}

// Let's also mock the UseCase to capture calls instead of injecting deeply if preferred.
// OR we use the real use case with mocked services. We'll use the real use case to test integration.

void main() {
  late MockNotificationService notificationService;
  late MockSmsService smsService;
  late MockAudioService audioService;
  late MockLocationService locationService;
  late MockConnectivityService connectivityService;
  late MockContactsRepository contactsRepository;
  late MockSosHistoryDatasource sosHistoryDatasource;
  late MockBox mockBox;

  late TriggerSosUseCase triggerSosUseCase;
  late SosCubit sosCubit;

  setUpAll(() {
    registerFallbackValue(SosHistoryEntry(
      timestamp: DateTime.now(), 
      contactsNotified: 0, 
      smsSentCount: 0, 
      wasCancelled: false
    ));
  });

  setUp(() {
    notificationService = MockNotificationService();
    smsService = MockSmsService();
    audioService = MockAudioService();
    locationService = MockLocationService();
    connectivityService = MockConnectivityService();
    contactsRepository = MockContactsRepository();
    sosHistoryDatasource = MockSosHistoryDatasource();
    mockBox = MockBox();

    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(null);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    when(() => mockBox.delete(any())).thenAnswer((_) async {});

    // Mock defaults
    when(() => notificationService.showSosNotification()).thenAnswer((_) async {});
    when(() => notificationService.cancelSosNotification()).thenAnswer((_) async {});
    when(() => audioService.playSiren()).thenAnswer((_) async {});
    when(() => audioService.stopAll()).thenAnswer((_) async {});
    
    when(() => connectivityService.isOnline).thenReturn(true);

    when(() => contactsRepository.getAll()).thenReturn([
      const EmergencyContact(id: '1', name: 'Mom', phone: '1234567890'),
    ]);
    
    final mockPos = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    when(() => locationService.getCurrentPosition()).thenAnswer((_) async => mockPos);
    when(() => locationService.lastPosition).thenReturn(mockPos);

    when(() => smsService.sendEmergencySms(
      contacts: any(named: 'contacts'),
      userName: any(named: 'userName'),
    )).thenAnswer((_) async => 1);

    when(() => sosHistoryDatasource.add(any())).thenAnswer((_) async {});

    // Real use case with mocked dependencies
    triggerSosUseCase = TriggerSosUseCase(
      smsService: smsService,
      locationService: locationService,
      notificationService: notificationService,
    );

    sosCubit = SosCubit(
      audioService: audioService,
      triggerSosUseCase: triggerSosUseCase,
      contactsRepository: contactsRepository,
      sosHistoryDatasource: sosHistoryDatasource,
      locationService: locationService,
      connectivityService: connectivityService,
      settingsBox: mockBox,
    );
  });

  tearDown(() {
    sosCubit.close();
  });

  group('SOS Notification Lifecycle Integration', () {
    test('showSosNotification is called when SOS executed via usecase', () async {
      await triggerSosUseCase.execute(contacts: [const EmergencyContact(id: '1', name: 'Mom', phone: '1234567890')]);
      
      verify(() => notificationService.showSosNotification()).called(1);
      verify(() => smsService.sendEmergencySms(contacts: any(named: 'contacts'), userName: any(named: 'userName'))).called(1);
    });

    test('cancelSosNotification is called when SOS deactivated via cubit', () async {
      // Deactivating in cubit cancels the use case, which cancels the notification
      await sosCubit.deactivateSos();
      
      verify(() => notificationService.cancelSosNotification()).called(1);
    });
  });
}
