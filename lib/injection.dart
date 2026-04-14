import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/auth_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/battery_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/context_alert_service.dart';
import 'core/services/decoy_call_service.dart';
import 'core/services/geofence_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sos_contact_alert_listener.dart';
import 'core/services/sos_event_service.dart';
import 'core/services/shake_detection_service.dart';
import 'core/services/snatch_detection_service.dart';
import 'core/services/sms_service.dart';
import 'core/services/speed_alert_service.dart';
import 'core/services/consent_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/premium_manager.dart';
import 'services/dead_man_switch_service.dart';
import 'core/services/weather_feed_service.dart';
import 'core/services/alert_permission_gate.dart';
import 'data/models/alert_preferences.dart';
import 'detection/ml/crash_fall_detection_service.dart';
import 'detection/ml/crash_fall_detection_engine.dart';
import 'core/services/voice_distress_service.dart';
import 'core/services/anomaly_movement_service.dart';
import 'core/services/road_condition_service.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'data/datasources/alerts_local_datasource.dart';
import 'data/datasources/contacts_cloud_sync.dart';
import 'data/datasources/contacts_local_datasource.dart';
import 'data/datasources/disaster_api_client.dart';
import 'data/datasources/military_alert_client.dart';
import 'data/datasources/weather_api_client.dart';
import 'data/datasources/overpass_api_client.dart';
import 'data/datasources/profile_local_datasource.dart';
import 'data/datasources/reminders_local_datasource.dart';
import 'data/datasources/sos_history_datasource.dart';
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
import 'presentation/blocs/alert_preferences/alert_preferences_cubit.dart';

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
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<BatteryService>(() => BatteryService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<SosContactAlertListener>(
    () => SosContactAlertListener(),
    dispose: (s) => s.stopListening(),
  );
  getIt.registerLazySingleton<ShakeDetectionService>(
    () => ShakeDetectionService(),
  );
  getIt.registerLazySingleton<SmsService>(
    () => SmsService(locationService: getIt<LocationService>()),
  );
  getIt.registerLazySingleton<DecoyCallService>(
    () => DecoyCallService(audioService: getIt<AudioService>()),
  );
  getIt.registerLazySingleton<SpeedAlertService>(
    () => SpeedAlertService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<GeofenceService>(
    () => GeofenceService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<SnatchDetectionService>(
    () => SnatchDetectionService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<ContextAlertService>(
    () => ContextAlertService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerSingleton<PremiumManager>(PremiumManager.instance);
  getIt.registerSingleton<SubscriptionService>(SubscriptionService.instance);
  getIt.registerSingleton<ConsentService>(ConsentService.instance);

  final contactsBox = await _openBoxSafe(ContactsLocalDataSource.boxName);
  getIt.registerLazySingleton<ContactsLocalDataSource>(
    () => ContactsLocalDataSource(contactsBox, getIt<PremiumManager>()),
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
    () => RemindersLocalDataSource(remindersBox, getIt<PremiumManager>()),
  );

  final sosHistoryBox = await _openBoxSafe(SosHistoryDatasource.boxName);
  getIt.registerLazySingleton<SosHistoryDatasource>(
    () => SosHistoryDatasource(sosHistoryBox),
  );

  // Centralized app settings box (used by splash, onboarding, settings).
  final appSettingsBox = await _openBoxSafe('app_settings');
  getIt.registerSingleton<Box>(appSettingsBox, instanceName: 'app_settings');

  // App lock service (uses app_settings box for PIN storage).
  getIt.registerLazySingleton<AppLockService>(
    () => AppLockService(settingsBox: appSettingsBox),
  );

  // Theme cubit (uses app_settings box for persistence).
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(settingsBox: appSettingsBox),
  );

  // Alert preferences (per-alert enable/disable).
  final alertPrefsBox = await _openBoxSafe(AlertPreferences.boxName);
  getIt.registerLazySingleton<AlertPreferences>(
    () => AlertPreferences(alertPrefsBox),
  );
  getIt.registerLazySingleton<AlertPermissionGate>(
    () => const AlertPermissionGate(),
  );

  // Crash/Fall detection service — load saved thresholds from Hive.
  final savedFallG = appSettingsBox.get('fall_threshold_g', defaultValue: 3.0) as double;
  final savedCrashG = appSettingsBox.get('crash_threshold_g', defaultValue: 4.0) as double;
  final savedMinConf = appSettingsBox.get('min_confidence', defaultValue: 0.5) as double;
  getIt.registerLazySingleton<CrashFallDetectionService>(
    () => CrashFallDetectionService(
      engine: CrashFallDetectionEngine(
        fallThresholdG: savedFallG,
        crashThresholdG: savedCrashG,
        minConfidence: savedMinConf,
      ),
    ),
    dispose: (s) => s.dispose(),
  );

  getIt.registerLazySingleton<VoiceDistressService>(
    () => VoiceDistressService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<AnomalyMovementService>(
    () => AnomalyMovementService(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<RoadConditionService>(
    () => RoadConditionService(),
    dispose: (s) => s.dispose(),
  );

  getIt.registerLazySingleton<DisasterApiClient>(
    () => DisasterApiClient(),
    dispose: (client) => client.dispose(),
  );

  getIt.registerLazySingleton<MilitaryAlertClient>(
    () => MilitaryAlertClient(),
    dispose: (client) => client.dispose(),
  );

  getIt.registerLazySingleton<WeatherApiClient>(
    () => WeatherApiClient(),
    dispose: (client) => client.dispose(),
  );

  getIt.registerLazySingleton<OverpassApiClient>(
    () => OverpassApiClient(),
    dispose: (client) => client.dispose(),
  );

  getIt.registerLazySingleton<WeatherFeedService>(
    () => WeatherFeedService(
      locationService: getIt<LocationService>(),
      weatherApiClient: getIt<WeatherApiClient>(),
      contextAlertService: getIt<ContextAlertService>(),
    ),
    dispose: (s) => s.dispose(),
  );

  getIt.registerLazySingleton<ContactsCloudSync>(
    () => ContactsCloudSync(authService: getIt<AuthService>()),
  );

  getIt.registerLazySingleton<ContactsRepository>(
    () => ContactsRepositoryImpl(getIt<ContactsLocalDataSource>()),
  );
  getIt.registerLazySingleton<AlertsRepository>(
    () => AlertsRepositoryImpl(
      apiClient: getIt<DisasterApiClient>(),
      militaryAlertClient: getIt<MilitaryAlertClient>(),
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

  getIt.registerLazySingleton<SosEventService>(
    () => SosEventService(),
  );

  getIt.registerLazySingleton<TriggerSosUseCase>(
    () => TriggerSosUseCase(
      smsService: getIt<SmsService>(),
      locationService: getIt<LocationService>(),
      notificationService: getIt<NotificationService>(),
      sosEventService: getIt<SosEventService>(),
    ),
  );

  getIt.registerLazySingleton<ContactsCubit>(
    () => ContactsCubit(
      getIt<ContactsRepository>(),
      cloudSync: getIt<ContactsCloudSync>(),
    ),
  );
  getIt.registerLazySingleton<SosCubit>(
    () => SosCubit(
      audioService: getIt<AudioService>(),
      triggerSosUseCase: getIt<TriggerSosUseCase>(),
      contactsRepository: getIt<ContactsRepository>(),
      sosHistoryDatasource: getIt<SosHistoryDatasource>(),
      locationService: getIt<LocationService>(),
      connectivityService: getIt<ConnectivityService>(),
      settingsBox: getIt<Box>(instanceName: 'app_settings'),
      smsService: getIt<SmsService>(),
      profileRepository: getIt<ProfileRepository>(),
    ),
  );
  // AlertsCubit registered BEFORE BatteryCubit (BatteryCubit depends on it).
  getIt.registerLazySingleton<AlertsCubit>(
    () => AlertsCubit(
      alertsRepository: getIt<AlertsRepository>(),
      notificationService: getIt<NotificationService>(),
      alertPreferences: getIt<AlertPreferences>(),
    ),
  );
  getIt.registerLazySingleton<BatteryCubit>(
    () => BatteryCubit(
      batteryService: getIt<BatteryService>(),
      notificationService: getIt<NotificationService>(),
      smsService: getIt<SmsService>(),
      contactsRepository: getIt<ContactsRepository>(),
      alertsCubit: getIt<AlertsCubit>(),
    ),
  );
  getIt.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<RemindersCubit>(
    () => RemindersCubit(
      repository: getIt<RemindersRepository>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
  getIt.registerLazySingleton<AlertPreferencesCubit>(
    () => AlertPreferencesCubit(
      alertPreferences: getIt<AlertPreferences>(),
      permissionGate: getIt<AlertPermissionGate>(),
      premiumManager: getIt<PremiumManager>(),
    ),
  );

  // Dead Man's Switch — periodic safety check-in timer.
  getIt.registerLazySingleton<DeadManSwitchService>(
    () => DeadManSwitchService(
      settingsBox: appSettingsBox,
      onTrigger: () {
        // When timer expires without check-in, auto-send SOS to all contacts.
        final contacts = getIt<ContactsRepository>().getAll();
        if (contacts.isNotEmpty) {
          getIt<SmsService>().sendEmergencySms(contacts: contacts);
        }
        getIt<NotificationService>().showDisasterAlert(
          title: 'Dead Man\'s Switch Triggered',
          body: 'You did not check in. Emergency SOS sent to your contacts.',
          soundName: 'phone_ring',
        );
      },
    ),
    dispose: (s) => s.dispose(),
  );
}

