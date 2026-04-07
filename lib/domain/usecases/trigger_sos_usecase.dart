import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sos_event_service.dart';
import '../../core/services/sms_service.dart';
import '../../data/models/emergency_contact.dart';

/// Signature for the phone-call launcher, extracted for testability.
///
/// In production: uses [launchUrl] with `tel:` URI.
/// In tests: replaced with a mock/stub that records the call target.
typedef PhoneCallLauncher = Future<bool> Function(Uri uri);

/// Use case that orchestrates the full SOS emergency flow.
///
/// When triggered:
/// 1. Get GPS location
/// 2. Send emergency SMS to all contacts with GPS link
/// 3. Auto-call the primary emergency contact
/// 4. Show persistent SOS notification (local)
/// 5. Write Firestore SOS event → triggers Cloud Function → FCM push to contacts
///
/// The Firestore write (step 5) is fire-and-forget.  Failure there is
/// non-fatal — SMS delivery is already complete at that point.
///
/// Audio (siren) is handled separately by SosCubit.
class TriggerSosUseCase {
  TriggerSosUseCase({
    required SmsService smsService,
    required LocationService locationService,
    required NotificationService notificationService,
    SosEventService? sosEventService,
    PhoneCallLauncher? phoneCallLauncher,
  })  : _smsService = smsService,
        _locationService = locationService,
        _notificationService = notificationService,
        _sosEventService = sosEventService,
        _phoneCallLauncher = phoneCallLauncher ?? launchUrl;

  final SmsService _smsService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final SosEventService? _sosEventService;

  /// Injected phone call launcher — defaults to [launchUrl].
  /// Tests inject a mock to avoid platform channel failures.
  final PhoneCallLauncher _phoneCallLauncher;

  /// Execute the SOS trigger flow.
  ///
  /// Returns a [SosResult] with SMS delivery counts and call status.
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

    // 3. Auto-call the primary emergency contact.
    //    Selects the contact marked isPrimary, or falls back to the first
    //    contact.  Uses tel: URI which triggers the OS dialer.  This runs
    //    AFTER SMS so messages are already sent even if the call fails.
    bool callInitiated = false;
    if (contacts.isNotEmpty) {
      callInitiated = await _callPrimaryContact(contacts);
    }

    // 4. Show persistent local notification.
    await _notificationService.showSosNotification();

    // 5. Write Firestore SOS event (fire-and-forget).
    if (_sosEventService != null) {
      try {
        unawaited(
          _sosEventService.recordSosEvent(
            triggerType: triggerType,
            latitude: position?.latitude,
            longitude: position?.longitude,
            contacts: contacts,
          ).catchError((Object e) {
            AppLogger.warning('[SOS] FCM event write failed (non-fatal): $e');
          }),
        );
      } catch (e) {
        AppLogger.warning('[SOS] FCM event service error (non-fatal): $e');
      }
    }

    return SosResult(
      smsSentCount: smsSent,
      totalContacts: contacts.length,
      hasLocation: position != null,
      callInitiated: callInitiated,
    );
  }

  /// Auto-call the primary emergency contact.
  ///
  /// Selection priority:
  /// 1. Contact with `isPrimary == true`
  /// 2. First contact in list (fallback)
  ///
  /// On Android: checks PHONE permission silently before dialing.
  /// On iOS: `tel:` URI always opens the Phone app (no permission needed).
  ///
  /// Returns `true` if the call was successfully initiated.
  Future<bool> _callPrimaryContact(List<EmergencyContact> contacts) async {
    // Find primary contact, or fall back to the first contact.
    final primary = contacts.cast<EmergencyContact?>().firstWhere(
          (c) => c!.isPrimary,
          orElse: () => null,
        ) ??
        contacts.first;

    final cleanPhone = primary.phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      AppLogger.warning('[SOS] Primary contact has no valid phone number');
      return false;
    }

    // On Android, check CALL_PHONE permission silently.
    if (Platform.isAndroid) {
      final hasPhonePermission = await Permission.phone.isGranted;
      if (!hasPhonePermission) {
        AppLogger.warning(
          '[SOS] CALL_PHONE permission not granted — opening dialer instead',
        );
      }
    }

    try {
      final uri = Uri.parse('tel:$cleanPhone');
      final launched = await _phoneCallLauncher(uri);
      if (launched) {
        AppLogger.info(
          '[SOS] Auto-call initiated to ${primary.name} ($cleanPhone)',
        );
      } else {
        AppLogger.warning(
          '[SOS] Failed to launch tel: URI for ${primary.name}',
        );
      }
      return launched;
    } catch (e) {
      AppLogger.warning('[SOS] Auto-call failed: $e');
      return false;
    }
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
    this.callInitiated = false,
  });

  final int smsSentCount;
  final int totalContacts;
  final bool hasLocation;

  /// Whether an auto-call was initiated to the primary contact.
  final bool callInitiated;

  bool get allSent => smsSentCount == totalContacts;
}
