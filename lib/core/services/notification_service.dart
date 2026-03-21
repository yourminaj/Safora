import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for displaying local notifications.
///
/// Handles SOS alerts, battery warnings, and disaster alerts.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification channels and settings.
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _isInitialized = true;
  }

  /// Show an SOS active notification (persistent, high priority).
  Future<void> showSosNotification() async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS Alerts',
      channelDescription: 'Emergency SOS alert notifications',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _plugin.show(
      id: 1, // SOS notification ID
      title: '🚨 SOS Alert Active',
      body: 'Emergency alert has been sent to your contacts.',
      notificationDetails: details,
    );
  }

  /// Show a low battery alert notification.
  Future<void> showBatteryAlert(int level) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Battery Alerts',
      channelDescription: 'Low battery warning notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
      ),
    );

    await _plugin.show(
      id: 2, // Battery notification ID
      title: '🔋 Low Battery Warning',
      body:
          'Your battery is at $level%. Your emergency contacts will be notified.',
      notificationDetails: details,
    );
  }

  /// Show a disaster alert notification.
  Future<void> showDisasterAlert({
    required String title,
    required String body,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'disaster_channel',
      'Disaster Alerts',
      channelDescription: 'Disaster and weather alert notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: DateTime.now().microsecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancel the SOS notification.
  Future<void> cancelSosNotification() async {
    await _plugin.cancel(id: 1);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
