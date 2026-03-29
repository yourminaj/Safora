import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/premium_manager.dart';
import 'core/services/app_open_ad_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/service_bootstrapper.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'core/services/app_logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/sos_foreground_service.dart';
import 'core/theme/app_theme.dart';
import 'injection.dart';

/// FCM background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are handled by the system notification tray.
}

void main() {
  // All initialization runs inside runZonedGuarded to ensure Flutter
  // bindings are created in the same zone as runApp (fixes zone mismatch).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Global Error Handling ──────────────────────────────
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

      // Initialize timezone data for scheduled notifications.
      tz.initializeTimeZones();

      // Initialize dependency injection (opens Hive boxes).
      await configureDependencies();

      // Load premium state from Hive (must run after DI opens boxes).
      await getIt<PremiumManager>().init();

      // Eagerly initialize notification channels + FCM.
      await getIt<NotificationService>().init();

      // Initialize SOS foreground service config.
      SosForegroundService.instance.init();

      // Initialize Google Mobile Ads SDK.
      await AdService.initialize();

      // Pre-load App Open Ad for foreground resumes.
      AppOpenAdService.instance.loadAd();

      // Sync premium state to ad services (single source of truth).
      AdService.instance.setPremium(getIt<PremiumManager>().isPremium);
      AppOpenAdService.instance.setPremium(getIt<PremiumManager>().isPremium);

      // Initialize RevenueCat subscription service.
      await getIt<SubscriptionService>().init();

      // ── Service Re-hydration ─────────────────────────────────
      final appSettings = getIt<Box>(instanceName: 'app_settings');
      await ServiceBootstrapper.bootstrap(sl: getIt, settings: appSettings);

      runApp(const SaforaApp());
    },
    AppLogger.handleUncaughtError,
  );
}

/// Root widget of the Safora application.
class SaforaApp extends StatefulWidget {
  const SaforaApp({super.key});

  @override
  State<SaforaApp> createState() => _SaforaAppState();
}

class _SaforaAppState extends State<SaforaApp> {
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;
  bool _lockScreenShowing = false;

  /// Tracks whether the app was actually sent to background (hidden).
  /// This prevents the lock from showing after dialogs, permissions,
  /// keyboard events, or other non-background lifecycle transitions.
  bool _wasInBackground = false;

  /// Cooldown timestamp after a successful unlock to prevent the
  /// lock screen from re-triggering immediately when the lifecycle
  /// resumes after the lock route pops.
  DateTime? _lastUnlockTime;

  /// Minimum time after unlock before the lock can show again.
  static const _unlockCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _router = createRouter();
    _lifecycleListener = AppLifecycleListener(
      // Track when app actually enters background.
      onHide: _onAppHidden,
      onResume: _onAppResumed,
      // App Open Ad on foreground restore.
      onShow: _onAppShown,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Called when the app is sent to background (task switcher, home button).
  void _onAppHidden() {
    _wasInBackground = true;
  }

  void _onAppResumed() {
    // Only show lock if the app was genuinely in the background.
    if (!_wasInBackground) return;
    _wasInBackground = false;

    // Don't re-trigger if we just unlocked (cooldown period).
    if (_lastUnlockTime != null &&
        DateTime.now().difference(_lastUnlockTime!) < _unlockCooldown) {
      return;
    }

    // Don't stack lock screens.
    if (_lockScreenShowing) return;

    try {
      final lockService = getIt<AppLockService>();
      if (lockService.isLockEnabled) {
        _lockScreenShowing = true;
        _router.push(AppRoutes.lock).then((_) {
          _lockScreenShowing = false;
          _lastUnlockTime = DateTime.now();
        });
      }
    } catch (_) {
      // AppLockService not registered yet during startup — ignore.
    }
  }

  /// Show App Open ad when the app becomes visible (e.g., from recents).
  void _onAppShown() {
    AppOpenAdService.instance.onAppResumed();
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = getIt<ThemeCubit>();
    return wrapWithProviders(
      BlocBuilder<ThemeCubit, ThemeMode>(
        bloc: themeCubit,
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Safora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: _router,

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
      ),
    );
  }
}
