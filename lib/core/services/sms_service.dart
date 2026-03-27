import 'dart:io';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/emergency_contact.dart';
import 'app_logger.dart';
import 'location_service.dart';

/// Service for sending emergency SMS messages.
///
/// On Android: sends SMS directly in the background via the `telephony` plugin.
/// On iOS: opens the Messages app pre-filled (Apple does not allow direct SMS).
class SmsService {
  SmsService({required LocationService locationService})
      : _locationService = locationService;

  final LocationService _locationService;

  /// Send an emergency SOS SMS to all provided contacts.
  ///
  /// Returns the number of SMS successfully sent (Android) or intents launched (iOS).
  Future<int> sendEmergencySms({
    required List<EmergencyContact> contacts,
    String? userName,
  }) async {
    if (contacts.isEmpty) return 0;

    final locationMsg = await _locationService.buildLocationMessage();
    final name = userName ?? 'Someone';
    final message = 'EMERGENCY SOS!\n\n'
        '$name needs immediate help!\n\n'
        '$locationMsg\n\n'
        'Sent via Safora';

    int sent = 0;
    for (final contact in contacts) {
      final success = await _sendSms(phone: contact.phone, message: message);
      if (success) sent++;
    }
    return sent;
  }

  /// Send a low-battery alert SMS to the primary contact.
  Future<bool> sendBatteryAlert({
    required EmergencyContact contact,
    required int batteryLevel,
    String? userName,
  }) async {
    final locationMsg = await _locationService.buildLocationMessage();
    final name = userName ?? 'Someone';

    final message = 'LOW BATTERY ALERT\n\n'
        '$name\'s phone is at $batteryLevel% battery.\n\n'
        'Last known $locationMsg\n\n'
        'Sent via Safora';

    return _sendSms(phone: contact.phone, message: message);
  }

  /// Send an "I Am Safe" message to all emergency contacts.
  ///
  /// Called when the user dismisses an emergency alert by confirming safety.
  /// Includes current location so contacts know where the user is.
  Future<int> sendIAmSafeSms({
    required List<EmergencyContact> contacts,
    String? userName,
  }) async {
    if (contacts.isEmpty) return 0;

    final locationMsg = await _locationService.buildLocationMessage();
    final name = userName ?? 'Someone';
    final message = 'I AM SAFE\n\n'
        '$name is confirming they are safe.\n\n'
        '$locationMsg\n\n'
        'Sent via Safora';

    int sent = 0;
    for (final contact in contacts) {
      final success = await _sendSms(phone: contact.phone, message: message);
      if (success) sent++;
    }
    return sent;
  }

  /// Send a custom alert SMS.
  Future<bool> sendAlertSms({
    required String phone,
    required String message,
  }) async {
    return _sendSms(phone: phone, message: message);
  }

  /// Route to direct send (Android) or url_launcher fallback (iOS).
  Future<bool> _sendSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (Platform.isAndroid) {
      return _sendDirectAndroid(cleanPhone, message);
    }
    return _sendViaUrlLauncher(cleanPhone, message);
  }

  /// Android: Send SMS directly in the background — no user interaction needed.
  Future<bool> _sendDirectAndroid(String phone, String message) async {
    try {
      final telephony = Telephony.instance;

      // Request SMS permission if not already granted.
      final hasPermission =
          await telephony.requestPhoneAndSmsPermissions ?? false;
      if (!hasPermission) {
        AppLogger.warning('[SMS] SMS permission denied, falling back');
        return _sendViaUrlLauncher(phone, message);
      }

      await telephony.sendSms(to: phone, message: message);
      AppLogger.info('[SMS] Sent directly to $phone');
      return true;
    } catch (e) {
      AppLogger.warning('[SMS] Direct send failed: $e — falling back');
      return _sendViaUrlLauncher(phone, message);
    }
  }

  /// iOS / fallback: Open the Messages app with pre-filled content.
  Future<bool> _sendViaUrlLauncher(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encodedMessage');

    try {
      return await launchUrl(uri);
    } catch (e) {
      AppLogger.warning('[SMS] url_launcher failed for $phone: $e');
      return false;
    }
  }
}
