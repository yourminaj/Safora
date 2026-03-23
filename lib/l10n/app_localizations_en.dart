// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Safora';

  @override
  String get allSafe => 'All Safe';

  @override
  String get noActiveThreats => 'No active threats detected';

  @override
  String get live => 'LIVE';

  @override
  String get tapToViewDetails => 'Tap to view details';

  @override
  String activeAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count Active Alert$_temp0';
  }

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
  String get alertMap => 'Alert Map';

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
  String get shareWithFirstResponders => 'Share with first responders';

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
  String get contactDetails => 'Contact Details';

  @override
  String get setAsPrimaryContact => 'Set as Primary Contact';

  @override
  String get maxContactsReached => 'Maximum 3 contacts for free tier';

  @override
  String get contactLimitReached => 'Contact Limit Reached';

  @override
  String get contactLimitMessage =>
      'Free users can add up to 3 emergency contacts.';

  @override
  String get premiumRoadmap =>
      'Premium features including unlimited contacts, all 127 risk types, and advanced detection will be available in an upcoming release.';

  @override
  String get removeContact => 'Remove Contact?';

  @override
  String removeContactConfirm(String name) {
    return 'Are you sure you want to remove $name from your emergency contacts?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get setAsPrimary => 'Set as Primary';

  @override
  String get ok => 'OK';

  @override
  String get primary => 'PRIMARY';

  @override
  String nContactsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count contact$_temp0 added';
  }

  @override
  String get noEmergencyContacts => 'No Emergency Contacts';

  @override
  String get addContactsHint =>
      'Add up to 3 trusted contacts who will be alerted during emergencies with your GPS location.';

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
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get manageProfile => 'Manage your medical profile';

  @override
  String get premium => 'Premium';

  @override
  String get unlockAllRiskTypes => 'Unlock all 127 risk types';

  @override
  String get saforaPremium => 'Safora Premium';

  @override
  String get currentFreePlan => 'Current free plan includes:';

  @override
  String get freeSos => '✅ SOS with SMS alerts';

  @override
  String get freeContacts => '✅ 3 emergency contacts';

  @override
  String get freeAlerts => '✅ Real-time disaster alerts';

  @override
  String get freeDetection => '✅ Crash & fall detection';

  @override
  String get freeMedicalId => '✅ Medical ID profile';

  @override
  String get pro => 'PRO';

  @override
  String get safety => 'Safety';

  @override
  String get shakeToSos => 'Shake to SOS';

  @override
  String get shakeToSosDesc => 'Shake your phone 3 times to trigger SOS';

  @override
  String get alertSounds => 'Alert Sounds';

  @override
  String get configureAlertSounds => 'Configure alert sounds';

  @override
  String get alertSoundSettings => 'Alert Sound Settings';

  @override
  String get alertSoundExplain =>
      'Alert sounds are configured automatically based on alert priority:';

  @override
  String get criticalSiren => '🔴 Critical — Emergency siren';

  @override
  String get highMediumWarning => '🟡 High / Medium — Warning tone';

  @override
  String get lowNotification => '🟢 Low — Gentle notification';

  @override
  String get customSoundFuture =>
      'Custom sound selection will be available in a future update.';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get languageExplain =>
      'Safora supports English and Bengali (বাংলা). The app language follows your device language setting automatically.';

  @override
  String get toChangeLanguage => 'To change the language, go to:';

  @override
  String get deviceSettingsLanguage => '📱 Device Settings → Language & Region';

  @override
  String get inAppLanguageFuture =>
      'In-app language switching will be available in a future update.';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System default';

  @override
  String get themeFollowsSystem => 'Theme follows system settings';

  @override
  String get about => 'About';

  @override
  String get saforaVersion => 'Safora v0.1.0';

  @override
  String get saforaLegalese => '© 2026 Safora Technologies';

  @override
  String get saforaAbout =>
      'Your Family\'s Safety Guardian — protecting you with real-time disaster alerts, SOS, and emergency notifications.';

  @override
  String get medicineReminders => '💊 Medicine Reminders';

  @override
  String nActive(int count) {
    return '$count active';
  }

  @override
  String get noRemindersSet => 'No reminders set';

  @override
  String get addRemindersHint =>
      'Add medicine reminders to get\ntimely notifications';

  @override
  String get lowBatteryWarning => 'Low Battery Warning';

  @override
  String batteryAt(int level) {
    return 'Your battery is at $level%.';
  }

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String routeNotFound(String route) {
    return 'Route not found: $route';
  }

  @override
  String get goHome => 'Go Home';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get relationship => 'Relationship (optional)';

  @override
  String get relationshipHint => 'e.g. Mother, Brother, Friend';

  @override
  String get enterName => 'Enter a name';

  @override
  String get enterPhone => 'Enter a phone number';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get primaryContactNotify =>
      'This contact will be notified first during emergencies.';

  @override
  String get sosAlertActivated => '🚨 SOS Alert activated! Siren playing.';

  @override
  String get stop => 'STOP';

  @override
  String get tapForHelp => 'TAP FOR HELP';

  @override
  String nAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count alert$_temp0';
  }

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get dosageHint => 'e.g. 500mg, 2 tablets';

  @override
  String get time => 'Time';

  @override
  String get frequency => 'Frequency';

  @override
  String get notes => 'Notes (optional)';

  @override
  String get notesHint => 'e.g. Take with food';

  @override
  String get enterMedicineName => 'Enter medicine name';

  @override
  String get enterDosage => 'Enter dosage';

  @override
  String get onceDailyLabel => 'Once daily';

  @override
  String get twiceDailyLabel => 'Twice daily';

  @override
  String get weeklyLabel => 'Weekly';

  @override
  String get asNeededLabel => 'As needed';

  @override
  String get sosAlertTitle => '🚨 SOS ALERT';

  @override
  String get emergencyAlertWillBeSent => 'Emergency alert will be sent in';

  @override
  String get seconds => 'seconds';

  @override
  String get sosContactsWillReceiveSms =>
      'Your emergency contacts will receive an SMS with your GPS location.';

  @override
  String get onboardingTitle1 => 'Stay Protected 24/7';

  @override
  String get onboardingDesc1 =>
      'Safora monitors for emergencies, disasters, and safety threats — alerting your family instantly with your GPS location.';

  @override
  String get onboardingTitle2 => 'Add Emergency Contacts';

  @override
  String get onboardingDesc2 =>
      'Add up to 3 trusted contacts. When danger strikes, they\'ll get an instant SMS with your exact location and alert type.';

  @override
  String get onboardingTitle3 => 'Your Medical Profile';

  @override
  String get onboardingDesc3 =>
      'Save your blood type, allergies, and medical conditions. First responders can access this info during emergencies.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get locationNeededSnack =>
      'Location is needed for SOS. Enable in Settings.';

  @override
  String get notificationsNeededSnack =>
      'Notifications are needed for alerts. Enable in Settings.';

  @override
  String get appTagline => 'Your Family\'s Safety Guardian';

  @override
  String mAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hAgo(int count) {
    return '${count}h ago';
  }

  @override
  String dAgo(int count) {
    return '${count}d ago';
  }
}
