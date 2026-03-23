import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/notification_service.dart';
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
  final mockAudio = MockAudioService();
  final mockUseCase = MockTriggerSosUseCase();
  final mockContacts = MockContactsRepository();
  final mockAlertsRepo = MockAlertsRepository();
  final mockProfileRepo = MockProfileRepository();
  final mockRemindersRepo = MockRemindersRepository();
  final mockNotificationSvc = MockNotificationService();

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

  return MultiBlocProvider(
    providers: [
      BlocProvider<SosCubit>(
        create: (_) =>
            sosCubit ??
            SosCubit(
              audioService: mockAudio,
              triggerSosUseCase: mockUseCase,
              contactsRepository: mockContacts,
            ),
      ),
      BlocProvider<AlertsCubit>(
        create: (_) =>
            alertsCubit ??
            AlertsCubit(
              alertsRepository: mockAlertsRepo,
              notificationService: mockNotificationSvc,
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
