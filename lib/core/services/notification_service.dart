import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_logger.dart';

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

    // ── Firebase Cloud Messaging ─────────────────────────
    await _initFcm();
  }

  /// Initialize Firebase Cloud Messaging for push notifications.
  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS prompts, Android auto-grants).
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token for this device and persist to Firestore.
    final token = await messaging.getToken();
    if (token != null) {
      AppLogger.info('[FCM] Token: ${token.substring(0, 20)}...');
      await _persistFcmToken(token);
    }

    // Listen for token refreshes (happens periodically or on reinstall).
    messaging.onTokenRefresh.listen((newToken) {
      AppLogger.info('[FCM] Token refreshed');
      _persistFcmToken(newToken);
    });

    // Handle foreground messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showDisasterAlert(
          title: notification.title ?? 'Safora Alert',
          body: notification.body ?? '',
        );
      }
    });
  }

  /// Save FCM token to Firestore for targeted push notifications.
  Future<void> _persistFcmToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.warning('[FCM] Token persistence failed: $e');
    }
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

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
