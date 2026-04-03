import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
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
        AndroidInitializationSettings('@drawable/ic_stat_safora');
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

    // Handle foreground messages — gated by alert priority for correct sound.
    //
    // The FCM data payload may include 'alert_type' or 'priority' fields.
    // If present, we resolve the correct sound (siren vs phone_ring).
    // If absent, we default to the notification ring (NOT siren) to prevent
    // false siren triggers from generic/test push notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      // Resolve sound from data payload, defaulting to notification ring.
      final soundName = _resolveFcmSoundName(message.data);

      showDisasterAlert(
        title: notification.title ?? 'Safora Alert',
        body: notification.body ?? '',
        soundName: soundName,
      );
    });
  }

  /// Resolve the notification sound name from the FCM data payload.
  ///
  /// **Sound policy:**
  /// - If `data['priority']` is `'critical'` → `'siren'` (emergency siren).
  /// - Everything else → `'phone_ring'` (notification ring).
  ///
  /// This prevents the siren from firing for generic, test, or non-critical
  /// push notifications sent from Firebase Console or backend.
  String _resolveFcmSoundName(Map<String, dynamic> data) {
    final priority = data['priority']?.toString().toLowerCase();
    if (priority == 'critical') {
      return 'siren';
    }
    // Default: safe notification ring — NEVER default to siren.
    return 'phone_ring';
  }

  /// Save FCM token to Firestore for targeted push notifications.
  ///
  /// Writes to TWO locations:
  /// 1. `users/{uid}` top-level document — used by `onSosTrigger` Cloud
  ///    Function to resolve `safetyContactPhone → fcmToken` for multicast push.
  /// 2. `users/{uid}/fcm_tokens/{token}` sub-collection — audit trail / multi-device support.
  Future<void> _persistFcmToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await usersRef.set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmPlatform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      await usersRef.collection('fcm_tokens').doc(token).set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('[FCM] Token persisted for uid=${user.uid}');
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
      icon: '@drawable/ic_stat_safora',
      color: Color(0xFFEF4444),
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
      title: 'SOS Alert Active',
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
      icon: '@drawable/ic_stat_safora',
      color: Color(0xFFF59E0B),
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
      title: 'Low Battery Warning',
      body:
          'Your battery is at $level%. Your emergency contacts will be notified.',
      notificationDetails: details,
    );
  }

  /// Show a disaster alert notification.
  Future<void> showDisasterAlert({
    required String title,
    required String body,
    String? soundName,
    Color? color,
  }) async {
    await init();
    
    // Setup audio logic if soundName is provided
    final String? androidSound = soundName; // e.g. "siren" (without extension)
    
    final androidDetails = AndroidNotificationDetails(
      'disaster_channel',
      'Disaster Alerts',
      channelDescription: 'Disaster and weather alert notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_stat_safora',
      color: color ?? const Color(0xFF1E3A8A),
      styleInformation: BigTextStyleInformation(body),
      sound: androidSound != null ? RawResourceAndroidNotificationSound(androidSound) : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: androidSound != null ? '$androidSound.mp3' : null,
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

  /// Schedule a recurring daily notification at [hour]:[minute].
  ///
  /// Uses [zonedSchedule] with [DateTimeComponents.time] so the notification
  /// repeats every day at the specified time. If the time has already passed
  /// today, it schedules for tomorrow.
  Future<void> scheduleDaily({
    required int notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If the time has already passed today, schedule for tomorrow.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_channel',
      'Medicine Reminders',
      channelDescription: 'Daily medicine reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_stat_safora',
      color: Color(0xFF10B981),
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    AppLogger.info(
      '[NotificationService] Scheduled daily notification #$notificationId '
      'at $hour:${minute.toString().padLeft(2, '0')}',
    );
  }
}
