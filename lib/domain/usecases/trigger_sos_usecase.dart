import 'dart:async';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sos_event_service.dart';
import '../../core/services/sms_service.dart';
import '../../data/models/emergency_contact.dart';

/// Use case that orchestrates the full SOS emergency flow.
///
/// When triggered:
/// 1. Get GPS location
/// 2. Send emergency SMS to all contacts with GPS link
/// 3. Show persistent SOS notification (local)
/// 4. Write Firestore SOS event → triggers Cloud Function → FCM push to contacts
///
/// The Firestore write (step 4) is fire-and-forget.  Failure there is
/// non-fatal — SMS delivery is already complete at that point.
///
/// Audio (siren) is handled separately by SosCubit.
class TriggerSosUseCase {
  TriggerSosUseCase({
    required SmsService smsService,
    required LocationService locationService,
    required NotificationService notificationService,
    SosEventService? sosEventService,
  })  : _smsService = smsService,
        _locationService = locationService,
        _notificationService = notificationService,
        _sosEventService = sosEventService;

  final SmsService _smsService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  /// Optional: when provided, writes SOS events to Firestore to trigger
  /// the Cloud Function FCM push channel.  Null-safe — missing it only
  /// disables the FCM push; SMS continues to work.
  final SosEventService? _sosEventService;

  /// Execute the SOS trigger flow.
  ///
  /// Returns the number of SMS intents successfully launched.
  Future<SosResult> execute({
    required List<EmergencyContact> contacts,
    String? userName,
    String triggerType = 'manual',
  }) async {
    // 1. Pre-fetch GPS location (warms up cache for SMS).
    await _locationService.getCurrentPosition();
    final position = _locationService.lastPosition;

    // 2. Send emergency SMS to all contacts.
    int smsSent = 0;
    if (contacts.isNotEmpty) {
      smsSent = await _smsService.sendEmergencySms(
        contacts: contacts,
        userName: userName,
      );
    }

    // 3. Show persistent local notification.
    await _notificationService.showSosNotification();

    // 4. Write Firestore SOS event (fire-and-forget).
    //    This triggers the Cloud Function → FCM push to safety contacts
    //    who also have Safora installed.  SMS delivery is already done; a
    //    failure here MUST NOT affect the SosResult returned to SosCubit.
    if (_sosEventService != null) {
      unawaited(
        _sosEventService.recordSosEvent(
          triggerType: triggerType,
          latitude: position?.latitude,
          longitude: position?.longitude,
          contacts: contacts,
        ),
      );
    }

    return SosResult(
      smsSentCount: smsSent,
      totalContacts: contacts.length,
      hasLocation: position != null,
    );
  }

  /// Cancel the SOS (dismiss notification).
  Future<void> cancel() async {
    await _notificationService.cancelSosNotification();
  }
}

/// Result of an SOS trigger attempt.
class SosResult {
  const SosResult({
    required this.smsSentCount,
    required this.totalContacts,
    required this.hasLocation,
  });

  final int smsSentCount;
  final int totalContacts;
  final bool hasLocation;

  bool get allSent => smsSentCount == totalContacts;
}
