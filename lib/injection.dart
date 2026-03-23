import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'core/services/app_logger.dart';
import 'core/services/auth_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/battery_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/decoy_call_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/shake_detection_service.dart';
import 'core/services/sms_service.dart';
import 'detection/ml/crash_fall_detection_service.dart';
import 'data/datasources/alerts_local_datasource.dart';
import 'data/datasources/contacts_cloud_sync.dart';
import 'data/datasources/contacts_local_datasource.dart';
import 'data/datasources/disaster_api_client.dart';
import 'data/datasources/profile_local_datasource.dart';
import 'data/datasources/reminders_local_datasource.dart';
import 'data/repositories/alerts_repository.dart';
import 'data/repositories/contacts_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/reminders_repository.dart';
import 'domain/usecases/trigger_sos_usecase.dart';
import 'presentation/blocs/alerts/alerts_cubit.dart';
import 'presentation/blocs/battery/battery_cubit.dart';
import 'presentation/blocs/contacts/contacts_cubit.dart';
import 'presentation/blocs/profile/profile_cubit.dart';
import 'presentation/blocs/reminders/reminders_cubit.dart';
import 'presentation/blocs/sos/sos_cubit.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Opens a Hive box with corruption recovery.
///
/// If the box is corrupt (e.g., power loss during write), deletes and
/// recreates it to prevent a permanent crash loop on app startup.
Future<Box> _openBoxSafe(String name) async {
  try {
    return await Hive.openBox(name);
  } catch (e) {
    AppLogger.warning('[Hive] Box "$name" is corrupt, deleting and recreating: $e');
    await Hive.deleteBoxFromDisk(name);
    return await Hive.openBox(name);
  }
}

/// Sets up all dependency injection bindings.
///
/// Call this in main() after Hive is initialized.
Future<void> configureDependencies() async {
  // ── Core Services ──────────────────────────────────────
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<BatteryService>(() => BatteryService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<ShakeDetectionService>(
    () => ShakeDetectionService(),
  );
  getIt.registerLazySingleton<SmsService>(
    () => SmsService(locationService: getIt<LocationService>()),
  );
  getIt.registerLazySingleton<DecoyCallService>(
    () => DecoyCallService(audioService: getIt<AudioService>()),
  );
  getIt.registerLazySingleton<CrashFallDetectionService>(
    () => CrashFallDetectionService(),
  );

  // ── Data Sources (with corruption recovery) ────────────
  final contactsBox = await _openBoxSafe(ContactsLocalDataSource.boxName);
  getIt.registerLazySingleton<ContactsLocalDataSource>(
    () => ContactsLocalDataSource(contactsBox),
  );

  final alertsBox = await _openBoxSafe(AlertsLocalDataSource.boxName);
  getIt.registerLazySingleton<AlertsLocalDataSource>(
    () => AlertsLocalDataSource(alertsBox),
  );

  final profileBox = await _openBoxSafe(ProfileLocalDataSource.boxName);
  getIt.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSource(profileBox),
  );

  final remindersBox = await _openBoxSafe(RemindersLocalDataSource.boxName);
  getIt.registerLazySingleton<RemindersLocalDataSource>(
    () => RemindersLocalDataSource(remindersBox),
  );

  // Centralized app settings box (used by splash, onboarding, settings).
  final appSettingsBox = await _openBoxSafe('app_settings');
  getIt.registerSingleton<Box>(appSettingsBox, instanceName: 'app_settings');

  getIt.registerLazySingleton<DisasterApiClient>(
    () => DisasterApiClient(),
    dispose: (client) => client.dispose(),
  );

  getIt.registerLazySingleton<ContactsCloudSync>(
    () => ContactsCloudSync(authService: getIt<AuthService>()),
  );

  // ── Repositories ───────────────────────────────────────
  getIt.registerLazySingleton<ContactsRepository>(
    () => ContactsRepositoryImpl(getIt<ContactsLocalDataSource>()),
  );
  getIt.registerLazySingleton<AlertsRepository>(
    () => AlertsRepositoryImpl(
      apiClient: getIt<DisasterApiClient>(),
      localDataSource: getIt<AlertsLocalDataSource>(),
      locationService: getIt<LocationService>(),
    ),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileLocalDataSource>()),
  );
  getIt.registerLazySingleton<RemindersRepository>(
    () => RemindersRepositoryImpl(getIt<RemindersLocalDataSource>()),
  );

  // ── Use Cases ──────────────────────────────────────────
  getIt.registerLazySingleton<TriggerSosUseCase>(
    () => TriggerSosUseCase(
      smsService: getIt<SmsService>(),
      locationService: getIt<LocationService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  // ── BLoCs / Cubits ─────────────────────────────────────
  getIt.registerFactory<ContactsCubit>(
    () => ContactsCubit(getIt<ContactsRepository>()),
  );
  getIt.registerFactory<SosCubit>(
    () => SosCubit(
      audioService: getIt<AudioService>(),
      triggerSosUseCase: getIt<TriggerSosUseCase>(),
      contactsRepository: getIt<ContactsRepository>(),
    ),
  );
  getIt.registerFactory<BatteryCubit>(
    () => BatteryCubit(
      batteryService: getIt<BatteryService>(),
      notificationService: getIt<NotificationService>(),
      smsService: getIt<SmsService>(),
      contactsRepository: getIt<ContactsRepository>(),
    ),
  );
  getIt.registerFactory<AlertsCubit>(
    () => AlertsCubit(
      alertsRepository: getIt<AlertsRepository>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
  );
  getIt.registerFactory<RemindersCubit>(
    () => RemindersCubit(
      repository: getIt<RemindersRepository>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
}

