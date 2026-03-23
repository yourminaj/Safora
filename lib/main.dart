import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/shake_detection_service.dart';
import 'core/services/sos_foreground_service.dart';
import 'core/theme/app_theme.dart';
import 'injection.dart';
import 'presentation/blocs/sos/sos_cubit.dart';

/// FCM background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are handled by the system notification tray.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Error Handling ──────────────────────────────
  // Uses centralized AppLogger. When adding Firebase Crashlytics,
  // call AppLogger.configureCrashReporting() after Firebase.initializeApp().
  FlutterError.onError = AppLogger.handleFlutterError;

  // Show a friendly error widget in production instead of the red error screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Only show exception details in debug mode.
                if (kDebugMode)
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  )
                else
                  const Text(
                    'Please restart the app. If the problem persists, contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Lock to portrait mode.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive for local storage.
  await Hive.initFlutter();

  // ── Firebase (must init before services that depend on FCM) ──
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Wire Crashlytics into AppLogger for production error tracking.
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    AppLogger.configureCrashReporting(
      errorCallback: (msg, error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, reason: msg),
      flutterErrorCallback: (details) =>
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
    );
  }

  // Initialize dependency injection (opens Hive boxes).
  await configureDependencies();

  // Eagerly initialize notification channels + FCM.
  await getIt<NotificationService>().init();

  // Initialize SOS foreground service config.
  SosForegroundService.instance.init();

  // Initialize Google Mobile Ads SDK.
  await AdService.initialize();

  // Auto-start shake detection if user previously enabled it.
  final appSettings = getIt<Box>(instanceName: 'app_settings');
  final shakeEnabled = appSettings.get('shake_enabled', defaultValue: false) as bool;
  if (shakeEnabled) {
    getIt<ShakeDetectionService>().startListening(
      onShakeDetected: () => getIt<SosCubit>().startCountdown(),
    );
  }

  // Catch all uncaught async errors in the zone.
  runZonedGuarded(
    () => runApp(const SaforaApp()),
    AppLogger.handleUncaughtError,
  );
}

/// Root widget of the Safora application.
class SaforaApp extends StatelessWidget {
  const SaforaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return wrapWithProviders(
      MaterialApp.router(
        title: 'Safora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: createRouter(),

        // ── Localization ────────────────────────────────
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('bn'), // Bengali
        ],
      ),
    );
  }
}
