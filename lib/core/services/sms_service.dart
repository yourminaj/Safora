import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/emergency_contact.dart';
import '../../data/models/user_profile.dart';
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
    UserProfile? userProfile,
  }) async {
    if (contacts.isEmpty) return 0;

    final locationMsg = await _locationService.buildLocationMessage();
    final name = userName ?? userProfile?.fullName ?? 'Someone';
    final medicalInfo = _buildMedicalSummary(userProfile);
    final message = 'EMERGENCY SOS!\n\n'
        '$name needs immediate help!\n\n'
        '$medicalInfo'
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

  /// Build a concise medical summary for emergency SMS.
  String _buildMedicalSummary(UserProfile? profile) {
    if (profile == null) return '';

    final parts = <String>[];
    if (profile.bloodType != null && profile.bloodType!.isNotEmpty) {
      parts.add('Blood: ${profile.bloodType}');
    }
    if (profile.allergies.isNotEmpty) {
      parts.add('Allergies: ${profile.allergies.join(', ')}');
    }
    if (profile.medicalConditions.isNotEmpty) {
      parts.add('Conditions: ${profile.medicalConditions.join(', ')}');
    }
    if (profile.medications.isNotEmpty) {
      parts.add('Meds: ${profile.medications.join(', ')}');
    }

    if (parts.isEmpty) return '';
    return 'MEDICAL: ${parts.join(' | ')}\n\n';
  }

  /// Route to direct send (Android) or url_launcher fallback (iOS).
  Future<bool> _sendSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.length < 7) {
      AppLogger.warning('[SMS] Invalid phone number (too short): $phone');
      return false;
    }

    if (Platform.isAndroid) {
      return _sendDirectAndroid(cleanPhone, message);
    }
    return _sendViaUrlLauncher(cleanPhone, message);
  }

  /// Android: Send SMS directly in the background — no user interaction needed.
  Future<bool> _sendDirectAndroid(String phone, String message) async {
    try {
      final telephony = Telephony.instance;

      // Check permission silently; avoid UI requests from background thread!
      final hasPermission = await Permission.sms.isGranted;
      if (!hasPermission) {
        AppLogger.warning('[SMS] SMS permission not granted (falling back). Required permissions must be granted via UI gate.');
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
