import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sms_service.dart';
import '../../data/models/emergency_contact.dart';

/// Use case that orchestrates the full SOS emergency flow.
///
/// When triggered:
/// 1. Get GPS location
/// 2. Send emergency SMS to all contacts with GPS link
/// 3. Show persistent SOS notification
///
/// Audio (siren) is handled separately by SosCubit.
class TriggerSosUseCase {
  TriggerSosUseCase({
    required SmsService smsService,
    required LocationService locationService,
    required NotificationService notificationService,
  })  : _smsService = smsService,
        _locationService = locationService,
        _notificationService = notificationService;

  final SmsService _smsService;
  final LocationService _locationService;
  final NotificationService _notificationService;

  /// Execute the SOS trigger flow.
  ///
  /// Returns the number of SMS intents successfully launched.
  Future<SosResult> execute({
    required List<EmergencyContact> contacts,
    String? userName,
  }) async {
    // 1. Pre-fetch GPS location (warms up cache for SMS).
    await _locationService.getCurrentPosition();

    // 2. Send emergency SMS to all contacts.
    int smsSent = 0;
    if (contacts.isNotEmpty) {
      smsSent = await _smsService.sendEmergencySms(
        contacts: contacts,
        userName: userName,
      );
    }

    // 3. Show persistent notification.
    await _notificationService.showSosNotification();

    return SosResult(
      smsSentCount: smsSent,
      totalContacts: contacts.length,
      hasLocation: _locationService.lastPosition != null,
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
