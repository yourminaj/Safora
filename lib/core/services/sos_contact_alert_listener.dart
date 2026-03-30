import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_logger.dart';

/// Free alternative to Firebase Cloud Functions for SOS push notifications.
///
/// ## How it works (no server required, Spark plan compatible)
///
/// When User A triggers SOS, [SosEventService] writes a document to:
/// ```
///   users/{uidA}/sos_events/{eventId}
///   {
///     contactPhones: ["+8801712345678", ...],
///     triggeredAt: Timestamp,
///     senderName: "Alice",
///     locationUrl: "https://maps.google.com/?q=...",
///     triggerType: "manual" | "shake" | "crash" | "dead_man_switch",
///   }
/// ```
///
/// Every contact who has Safora installed runs this service. It opens a
/// `collectionGroup('sos_events')` listener filtered to docs where
/// `contactPhones` contains *this user's own phone number*.
///
/// Firestore maintains the real-time WebSocket connection through the OS,
/// so the listener fires even when the app is in the background (as long
/// as the foreground service keeps the process alive on Android).
///
/// ## Reliability
/// SMS (already implemented) is the PRIMARY alert channel. This listener
/// is the SECONDARY in-app push channel — works completely free, no
/// Cloud Functions or Blaze plan required.
///
/// ## Firestore Security Rule required
/// ```
/// match /users/{uid}/sos_events/{eventId} {
///   allow read: if request.auth != null
///     && resource.data.contactPhones
///          .hasAny([request.auth.token.phone_number]);
/// }
/// ```
class SosContactAlertListener {
  SosContactAlertListener({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _notifications;

  StreamSubscription<QuerySnapshot>? _subscription;
  bool _notificationsReady = false;

  /// Anchor timestamp: only react to SOS events created AFTER we started.
  late Timestamp _startedAt;

  static const _channelId = 'sos_contact_alerts';
  static const _channelName = 'SOS Contact Alerts';
  static const _channelDesc =
      'Alerts when one of your contacts triggers an SOS emergency';

  // PUBLIC API

  /// Start listening for incoming SOS events from contacts.
  ///
  /// Safe to call multiple times — no-op if already listening.
  Future<void> startListening() async {
    if (_subscription != null) return;

    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.warning('[SosContactAlert] No signed-in user — skipping listener');
      return;
    }

    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) {
      AppLogger.warning('[SosContactAlert] No phone number on account — skipping listener');
      return;
    }

    await _ensureNotificationsReady();

    _startedAt = Timestamp.now();

    AppLogger.info(
      '[SosContactAlert] Starting listener for ${_maskPhone(phone)}',
    );

    _subscription = _db
        .collectionGroup('sos_events')
        .where('contactPhones', arrayContains: phone)
        .where('triggeredAt', isGreaterThan: _startedAt)
        .orderBy('triggeredAt', descending: true)
        .limit(5)
        .snapshots()
        .listen(
          _onSnapshot,
          onError: (Object e) =>
              AppLogger.warning('[SosContactAlert] Stream error: $e'),
        );

    AppLogger.info('[SosContactAlert] ✅ Listener active');
  }

  /// Stop listening. Call on sign-out or app disposal.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    AppLogger.info('[SosContactAlert] Listener stopped');
  }

  // PRIVATE

  void _onSnapshot(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final senderName = (data['senderName'] as String?) ?? 'Your contact';
      final locationUrl = data['locationUrl'] as String?;
      final triggerType = (data['triggerType'] as String?) ?? 'manual';

      AppLogger.info(
        '[SosContactAlert] 🚨 SOS from $senderName (type: $triggerType)',
      );

      _showAlert(
        senderName: senderName,
        locationUrl: locationUrl,
        docId: change.doc.id,
      );
    }
  }

  Future<void> _showAlert({
    required String senderName,
    required String? locationUrl,
    required String docId,
  }) async {
    final body = locationUrl != null
        ? '$senderName needs emergency help!\n📍 Tap to view their location.'
        : '$senderName needs emergency help! GPS unavailable.';

    // Use non-const so we can use the Color from material.
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFD32F2F),
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.alarm,
      ticker: 'SOS Alert',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await _notifications.show(
      id: docId.hashCode & 0x7FFFFFFF,
      title: '🚨 SOS — $senderName needs help!',
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: locationUrl,
    );
  }

  Future<void> _ensureNotificationsReady() async {
    if (_notificationsReady) return;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    _notificationsReady = true;
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
  }
}
