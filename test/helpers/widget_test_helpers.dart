import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/auth_service.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/datasources/contacts_cloud_sync.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/alerts_repository.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/data/repositories/profile_repository.dart';
import 'package:safora/data/repositories/reminders_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:safora/presentation/blocs/profile/profile_cubit.dart';
import 'package:safora/presentation/blocs/reminders/reminders_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';

// ─── Mocks ────────────────────────────────────────────────────
class MockAudioService extends Mock implements AudioService {}

class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockAlertsRepository extends Mock implements AlertsRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockRemindersRepository extends Mock implements RemindersRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAuthService extends Mock implements AuthService {}

class MockContactsCloudSync extends Mock implements ContactsCloudSync {}

class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}

class MockLocationService extends Mock implements LocationService {}

class MockAlertPreferences extends Mock implements AlertPreferences {}

// ─── Test Wrapper ─────────────────────────────────────────────
/// Wraps a widget under test with all required providers and
/// MaterialApp shell so localization and BLoC access work in tests.
Widget buildTestableWidget({
  required Widget child,
  SosCubit? sosCubit,
  AlertsCubit? alertsCubit,
  ContactsCubit? contactsCubit,
  ProfileCubit? profileCubit,
  RemindersCubit? remindersCubit,
}) {
  // Register fallback values for mocktail.
  registerFallbackValue(SosHistoryEntry(
    timestamp: DateTime(2020),
    contactsNotified: 0,
    smsSentCount: 0,
    wasCancelled: false,
  ));
  final mockAudio = MockAudioService();
  final mockUseCase = MockTriggerSosUseCase();
  final mockContacts = MockContactsRepository();
  final mockAlertsRepo = MockAlertsRepository();
  final mockProfileRepo = MockProfileRepository();
  final mockRemindersRepo = MockRemindersRepository();
  final mockNotificationSvc = MockNotificationService();
  final mockHistory = MockSosHistoryDatasource();
  final mockLocation = MockLocationService();

  // Register GetIt mocks for screens that use getIt<> directly.
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<AuthService>()) {
    final mockAuth = MockAuthService();
    when(() => mockAuth.isSignedIn).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(null);
    getIt.registerSingleton<AuthService>(mockAuth);
  }
  if (!getIt.isRegistered<ContactsCloudSync>()) {
    getIt.registerSingleton<ContactsCloudSync>(MockContactsCloudSync());
  }

  // Stub commonly-called methods.
  when(() => mockAudio.playSiren()).thenAnswer((_) async {});
  when(() => mockAudio.stopAll()).thenAnswer((_) async {});
  when(() => mockUseCase.cancel()).thenAnswer((_) async {});
  when(() => mockContacts.getAll()).thenReturn([]);
  when(() => mockAlertsRepo.fetchLatestAlerts()).thenAnswer((_) async => []);
  when(() => mockAlertsRepo.getAlertHistory(limit: any(named: 'limit')))
      .thenReturn([]);
  when(() => mockAlertsRepo.getAlertHistory()).thenReturn([]);
  when(() => mockProfileRepo.load()).thenReturn(null);
  when(
    () => mockUseCase.execute(
      contacts: any(named: 'contacts'),
      userName: any(named: 'userName'),
    ),
  ).thenAnswer(
    (_) async => const SosResult(
      smsSentCount: 0,
      totalContacts: 0,
      hasLocation: false,
    ),
  );
  when(() => mockHistory.add(any())).thenAnswer((_) async {});
  when(() => mockLocation.lastPosition).thenReturn(null);

  final mockPrefs = MockAlertPreferences();
    when(() => mockPrefs.isEnabled(any())).thenReturn(true);

    return MultiBlocProvider(
    providers: [
      BlocProvider<SosCubit>(
        create: (_) =>
            sosCubit ??
            SosCubit(
              audioService: mockAudio,
              triggerSosUseCase: mockUseCase,
              contactsRepository: mockContacts,
              sosHistoryDatasource: mockHistory,
              locationService: mockLocation,
            ),
      ),
      BlocProvider<AlertsCubit>(
        create: (_) =>
            alertsCubit ??
            AlertsCubit(
              alertsRepository: mockAlertsRepo,
              notificationService: mockNotificationSvc,
              alertPreferences: mockPrefs,
            ),
      ),
      BlocProvider<ContactsCubit>(
        create: (_) => contactsCubit ?? ContactsCubit(mockContacts),
      ),
      BlocProvider<ProfileCubit>(
        create: (_) =>
            profileCubit ??
            ProfileCubit(profileRepository: mockProfileRepo),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) =>
            remindersCubit ??
            RemindersCubit(
              repository: mockRemindersRepo,
              notificationService: mockNotificationSvc,
            ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}
