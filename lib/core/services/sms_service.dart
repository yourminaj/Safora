import 'package:url_launcher/url_launcher.dart';
import '../../data/models/emergency_contact.dart';
import 'location_service.dart';

/// Service for sending emergency SMS messages.
///
/// Uses `url_launcher` with `sms:` URI scheme for cross-platform SMS.
/// On iOS, this opens the Messages app pre-filled.
/// On Android, this opens the default SMS app pre-filled.
class SmsService {
  SmsService({required LocationService locationService})
      : _locationService = locationService;

  final LocationService _locationService;

  /// Send an emergency SOS SMS to all provided contacts.
  ///
  /// The message includes the user's GPS location and a Google Maps link.
  /// Returns the number of SMS intents successfully launched.
  Future<int> sendEmergencySms({
    required List<EmergencyContact> contacts,
    String? userName,
  }) async {
    if (contacts.isEmpty) return 0;

    // Build location message.
    final locationMsg = await _locationService.buildLocationMessage();

    // Compose the full emergency message.
    final name = userName ?? 'Someone';
    final message = '🚨 EMERGENCY SOS!\n\n'
        '$name needs immediate help!\n\n'
        '$locationMsg\n\n'
        'Sent via Safora';

    int sent = 0;
    for (final contact in contacts) {
      final success = await _sendSms(
        phone: contact.phone,
        message: message,
      );
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

    final message = '🔋 LOW BATTERY ALERT\n\n'
        '$name\'s phone is at $batteryLevel% battery.\n\n'
        'Last known $locationMsg\n\n'
        'Sent via Safora';

    return _sendSms(phone: contact.phone, message: message);
  }

  /// Send a custom alert SMS.
  Future<bool> sendAlertSms({
    required String phone,
    required String message,
  }) async {
    return _sendSms(phone: phone, message: message);
  }

  /// Launch the SMS app with pre-filled recipient and body.
  Future<bool> _sendSms({
    required String phone,
    required String message,
  }) async {
    // Clean phone number.
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encodedMessage = Uri.encodeComponent(message);

    final uri = Uri.parse('sms:$cleanPhone?body=$encodedMessage');

    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
