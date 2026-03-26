import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'app_logger.dart';

/// SOS Foreground Service — keeps SOS monitoring alive in the background.
///
/// When activated, shows a persistent notification "Safora is protecting you"
/// and continues to monitor for shake/crash/fall events even when the app
/// is in the background or the screen is off.
class SosForegroundService {
  SosForegroundService._();

  static final SosForegroundService instance = SosForegroundService._();

  bool _isInitialized = false;

  /// Initialize the foreground task configuration.
  void init() {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'safora_sos_service',
        channelName: 'Safora SOS Protection',
        channelDescription:
            'Keeps SOS monitoring active in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _isInitialized = true;
  }

  /// Start the SOS foreground service with a persistent notification.
  Future<ServiceRequestResult> start() async {
    init();

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }

    return FlutterForegroundTask.startService(
      notificationTitle: 'Safora is protecting you',
      notificationText: 'SOS monitoring is active',
      callback: startCallback,
    );
  }

  /// Stop the foreground service.
  Future<ServiceRequestResult> stop() {
    return FlutterForegroundTask.stopService();
  }

  /// Whether the service is currently running.
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}

/// Top-level callback that runs when the foreground service starts.
///
/// This runs in a separate isolate on Android.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SosTaskHandler());
}

/// Task handler that runs the SOS monitoring loop in the background.
class SosTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.info('[SosForegroundService] Background task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This runs every 5 seconds in the background.
    // The actual sensor monitoring is done by CrashFallDetectionService
    // and ShakeDetectionService which run independently via their
    // stream subscriptions. This handler just keeps the service alive.
    FlutterForegroundTask.updateService(
      notificationTitle: 'Safora is protecting you',
      notificationText: 'SOS monitoring active',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.info('[SosForegroundService] Background task stopped');
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_sos') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    // Bring the app to the foreground when the user taps the notification.
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    // Service continues running even if notification is swiped.
  }
}
