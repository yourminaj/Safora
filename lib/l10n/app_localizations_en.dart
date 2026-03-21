// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Safora SOS';

  @override
  String get allSafe => 'All Safe';

  @override
  String get noActiveThreats => 'No active threats detected';

  @override
  String get live => 'LIVE';

  @override
  String get sosButton => 'SOS';

  @override
  String sosCountdown(int seconds) {
    return 'SOS in $seconds seconds';
  }

  @override
  String get sosActive => 'SOS Alert Active';

  @override
  String get sosCancelled => 'SOS Cancelled';

  @override
  String get tapToCancel => 'Tap to cancel';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get decoyCall => 'Decoy Call';

  @override
  String get contacts => 'Contacts';

  @override
  String get medicalId => 'Medical ID';

  @override
  String get alerts => 'Alerts';

  @override
  String get liveMap => 'Live Map';

  @override
  String get reminders => 'Reminders';

  @override
  String get recentAlerts => 'Recent Alerts';

  @override
  String get seeAll => 'See All';

  @override
  String get noRecentAlerts => 'No recent alerts';

  @override
  String get allClear => 'All Clear!';

  @override
  String get noActiveAlerts =>
      'No active alerts in your area. We monitor 127 risk types to keep you safe.';

  @override
  String get disasterAlerts => 'Disaster Alerts';

  @override
  String get filterAll => 'All';

  @override
  String get filterCritical => 'Critical';

  @override
  String get filterDisaster => 'Disaster';

  @override
  String get filterWeather => 'Weather';

  @override
  String get filterWater => 'Water';

  @override
  String get autoRefreshNote => 'Auto-refreshes every 15 min';

  @override
  String get unableToLoadAlerts => 'Unable to load alerts';

  @override
  String get checkConnection => 'Check your internet connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get medicalProfile => 'Medical Profile';

  @override
  String get editMedicalProfile => 'Edit Medical Profile';

  @override
  String get createMedicalProfile => 'Create Medical Profile';

  @override
  String get noMedicalProfile => 'No Medical Profile';

  @override
  String get createProfileHint =>
      'Create your medical profile so first responders can access your vital information in emergencies.';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get fullName => 'Full Name';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get allergies => 'Allergies';

  @override
  String get medicalConditions => 'Medical Conditions';

  @override
  String get medications => 'Medications';

  @override
  String get emergencyNotes => 'Emergency Notes';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get height => 'Height (cm)';

  @override
  String get organDonor => 'Organ Donor';

  @override
  String get separateWithCommas => 'Separate with commas';

  @override
  String get nameRequired => 'Name required';

  @override
  String get save => 'Save';

  @override
  String get notSet => 'Not set';

  @override
  String get noneListed => 'None listed';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get addContact => 'Add Contact';

  @override
  String get editContact => 'Edit Contact';

  @override
  String get maxContactsReached => 'Maximum 3 contacts for free tier';

  @override
  String get incomingCall => 'Incoming call...';

  @override
  String get decline => 'Decline';

  @override
  String get answer => 'Answer';

  @override
  String get endCall => 'End Call';

  @override
  String get mute => 'Mute';

  @override
  String get keypad => 'Keypad';

  @override
  String get speaker => 'Speaker';

  @override
  String get settings => 'Settings';

  @override
  String get shakeToSos => 'Shake to SOS';

  @override
  String get shakeToSosDesc => 'Shake your phone 3 times to trigger SOS';

  @override
  String get lowBatteryWarning => 'Low Battery Warning';

  @override
  String batteryAt(int level) {
    return 'Your battery is at $level%.';
  }
}
