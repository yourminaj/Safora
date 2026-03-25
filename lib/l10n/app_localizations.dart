import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Safora'**
  String get appTitle;

  /// No description provided for @allSafe.
  ///
  /// In en, this message translates to:
  /// **'All Safe'**
  String get allSafe;

  /// No description provided for @noActiveThreats.
  ///
  /// In en, this message translates to:
  /// **'No active threats detected'**
  String get noActiveThreats;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @tapToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapToViewDetails;

  /// No description provided for @activeAlerts.
  ///
  /// In en, this message translates to:
  /// **'{count} Active Alert{count, plural, =1{} other{s}}'**
  String activeAlerts(int count);

  /// No description provided for @sosButton.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosButton;

  /// No description provided for @sosCountdown.
  ///
  /// In en, this message translates to:
  /// **'SOS in {seconds} seconds'**
  String sosCountdown(int seconds);

  /// No description provided for @sosActive.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert Active'**
  String get sosActive;

  /// No description provided for @sosCancelled.
  ///
  /// In en, this message translates to:
  /// **'SOS Cancelled'**
  String get sosCancelled;

  /// No description provided for @tapToCancel.
  ///
  /// In en, this message translates to:
  /// **'Tap to cancel'**
  String get tapToCancel;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @decoyCall.
  ///
  /// In en, this message translates to:
  /// **'Decoy Call'**
  String get decoyCall;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @medicalId.
  ///
  /// In en, this message translates to:
  /// **'Medical ID'**
  String get medicalId;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @alertMap.
  ///
  /// In en, this message translates to:
  /// **'Alert Map'**
  String get alertMap;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Alerts'**
  String get recentAlerts;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noRecentAlerts.
  ///
  /// In en, this message translates to:
  /// **'No recent alerts'**
  String get noRecentAlerts;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear!'**
  String get allClear;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts in your area. We monitor 127 risk types to keep you safe.'**
  String get noActiveAlerts;

  /// No description provided for @disasterAlerts.
  ///
  /// In en, this message translates to:
  /// **'Disaster Alerts'**
  String get disasterAlerts;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get filterCritical;

  /// No description provided for @filterDisaster.
  ///
  /// In en, this message translates to:
  /// **'Disaster'**
  String get filterDisaster;

  /// No description provided for @filterWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get filterWeather;

  /// No description provided for @filterWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get filterWater;

  /// No description provided for @autoRefreshNote.
  ///
  /// In en, this message translates to:
  /// **'Auto-refreshes every 15 min'**
  String get autoRefreshNote;

  /// No description provided for @unableToLoadAlerts.
  ///
  /// In en, this message translates to:
  /// **'Unable to load alerts'**
  String get unableToLoadAlerts;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get checkConnection;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @medicalProfile.
  ///
  /// In en, this message translates to:
  /// **'Medical Profile'**
  String get medicalProfile;

  /// No description provided for @editMedicalProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Medical Profile'**
  String get editMedicalProfile;

  /// No description provided for @createMedicalProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Medical Profile'**
  String get createMedicalProfile;

  /// No description provided for @noMedicalProfile.
  ///
  /// In en, this message translates to:
  /// **'No Medical Profile'**
  String get noMedicalProfile;

  /// No description provided for @createProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Create your medical profile so first responders can access your vital information in emergencies.'**
  String get createProfileHint;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @medicalConditions.
  ///
  /// In en, this message translates to:
  /// **'Medical Conditions'**
  String get medicalConditions;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @emergencyNotes.
  ///
  /// In en, this message translates to:
  /// **'Emergency Notes'**
  String get emergencyNotes;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get height;

  /// No description provided for @organDonor.
  ///
  /// In en, this message translates to:
  /// **'Organ Donor'**
  String get organDonor;

  /// No description provided for @shareWithFirstResponders.
  ///
  /// In en, this message translates to:
  /// **'Share with first responders'**
  String get shareWithFirstResponders;

  /// No description provided for @separateWithCommas.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get separateWithCommas;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get nameRequired;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noneListed.
  ///
  /// In en, this message translates to:
  /// **'None listed'**
  String get noneListed;

  /// No description provided for @bodyInfo.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get bodyInfo;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get editContact;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @setAsPrimaryContact.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary Contact'**
  String get setAsPrimaryContact;

  /// No description provided for @maxContactsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 contacts for free tier'**
  String get maxContactsReached;

  /// No description provided for @contactLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Contact Limit Reached'**
  String get contactLimitReached;

  /// No description provided for @contactLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Free users can add up to 3 emergency contacts.'**
  String get contactLimitMessage;

  /// No description provided for @premiumRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Premium features including unlimited contacts, all 127 risk types, and advanced detection will be available in an upcoming release.'**
  String get premiumRoadmap;

  /// No description provided for @removeContact.
  ///
  /// In en, this message translates to:
  /// **'Remove Contact?'**
  String get removeContact;

  /// No description provided for @removeContactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from your emergency contacts?'**
  String removeContactConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @setAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get setAsPrimary;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get primary;

  /// No description provided for @nContactsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} contact{count, plural, =1{} other{s}} added'**
  String nContactsAdded(int count);

  /// No description provided for @noEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'No Emergency Contacts'**
  String get noEmergencyContacts;

  /// No description provided for @addContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 trusted contacts who will be alerted during emergencies with your GPS location.'**
  String get addContactsHint;

  /// No description provided for @incomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call...'**
  String get incomingCall;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCall;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @keypad.
  ///
  /// In en, this message translates to:
  /// **'Keypad'**
  String get keypad;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @manageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage your medical profile'**
  String get manageProfile;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @unlockAllRiskTypes.
  ///
  /// In en, this message translates to:
  /// **'Unlock all 127 risk types'**
  String get unlockAllRiskTypes;

  /// No description provided for @saforaPremium.
  ///
  /// In en, this message translates to:
  /// **'Safora Premium'**
  String get saforaPremium;

  /// No description provided for @currentFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Current free plan includes:'**
  String get currentFreePlan;

  /// No description provided for @freeSos.
  ///
  /// In en, this message translates to:
  /// **'✅ SOS with SMS alerts'**
  String get freeSos;

  /// No description provided for @freeContacts.
  ///
  /// In en, this message translates to:
  /// **'✅ 3 emergency contacts'**
  String get freeContacts;

  /// No description provided for @freeAlerts.
  ///
  /// In en, this message translates to:
  /// **'✅ Real-time disaster alerts'**
  String get freeAlerts;

  /// No description provided for @freeDetection.
  ///
  /// In en, this message translates to:
  /// **'✅ Crash & fall detection'**
  String get freeDetection;

  /// No description provided for @freeMedicalId.
  ///
  /// In en, this message translates to:
  /// **'✅ Medical ID profile'**
  String get freeMedicalId;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @shakeToSos.
  ///
  /// In en, this message translates to:
  /// **'Shake to SOS'**
  String get shakeToSos;

  /// No description provided for @shakeToSosDesc.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone 3 times to trigger SOS'**
  String get shakeToSosDesc;

  /// No description provided for @alertSounds.
  ///
  /// In en, this message translates to:
  /// **'Alert Sounds'**
  String get alertSounds;

  /// No description provided for @configureAlertSounds.
  ///
  /// In en, this message translates to:
  /// **'Configure alert sounds'**
  String get configureAlertSounds;

  /// No description provided for @alertSoundSettings.
  ///
  /// In en, this message translates to:
  /// **'Alert Sound Settings'**
  String get alertSoundSettings;

  /// No description provided for @alertSoundExplain.
  ///
  /// In en, this message translates to:
  /// **'Alert sounds are configured automatically based on alert priority:'**
  String get alertSoundExplain;

  /// No description provided for @criticalSiren.
  ///
  /// In en, this message translates to:
  /// **'🔴 Critical — Emergency siren'**
  String get criticalSiren;

  /// No description provided for @highMediumWarning.
  ///
  /// In en, this message translates to:
  /// **'🟡 High / Medium — Warning tone'**
  String get highMediumWarning;

  /// No description provided for @lowNotification.
  ///
  /// In en, this message translates to:
  /// **'🟢 Low — Gentle notification'**
  String get lowNotification;

  /// No description provided for @customSoundFuture.
  ///
  /// In en, this message translates to:
  /// **'Custom sound selection will be available in a future update.'**
  String get customSoundFuture;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @languageExplain.
  ///
  /// In en, this message translates to:
  /// **'Safora supports English and Bengali (বাংলা). The app language follows your device language setting automatically.'**
  String get languageExplain;

  /// No description provided for @toChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'To change the language, go to:'**
  String get toChangeLanguage;

  /// No description provided for @deviceSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'📱 Device Settings → Language & Region'**
  String get deviceSettingsLanguage;

  /// No description provided for @inAppLanguageFuture.
  ///
  /// In en, this message translates to:
  /// **'In-app language switching will be available in a future update.'**
  String get inAppLanguageFuture;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @themeFollowsSystem.
  ///
  /// In en, this message translates to:
  /// **'Theme follows system settings'**
  String get themeFollowsSystem;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @saforaVersion.
  ///
  /// In en, this message translates to:
  /// **'Safora v0.1.0'**
  String get saforaVersion;

  /// No description provided for @saforaLegalese.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Safora Technologies'**
  String get saforaLegalese;

  /// No description provided for @saforaAbout.
  ///
  /// In en, this message translates to:
  /// **'Your Family\'s Safety Guardian — protecting you with real-time disaster alerts, SOS, and emergency notifications.'**
  String get saforaAbout;

  /// No description provided for @medicineReminders.
  ///
  /// In en, this message translates to:
  /// **'💊 Medicine Reminders'**
  String get medicineReminders;

  /// No description provided for @nActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String nActive(int count);

  /// No description provided for @noRemindersSet.
  ///
  /// In en, this message translates to:
  /// **'No reminders set'**
  String get noRemindersSet;

  /// No description provided for @addRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Add medicine reminders to get\ntimely notifications'**
  String get addRemindersHint;

  /// No description provided for @lowBatteryWarning.
  ///
  /// In en, this message translates to:
  /// **'Low Battery Warning'**
  String get lowBatteryWarning;

  /// No description provided for @batteryAt.
  ///
  /// In en, this message translates to:
  /// **'Your battery is at {level}%.'**
  String batteryAt(int level);

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {route}'**
  String routeNotFound(String route);

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship (optional)'**
  String get relationship;

  /// No description provided for @relationshipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mother, Brother, Friend'**
  String get relationshipHint;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get enterPhone;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @primaryContactNotify.
  ///
  /// In en, this message translates to:
  /// **'This contact will be notified first during emergencies.'**
  String get primaryContactNotify;

  /// No description provided for @sosAlertActivated.
  ///
  /// In en, this message translates to:
  /// **'🚨 SOS Alert activated! Siren playing.'**
  String get sosAlertActivated;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @tapForHelp.
  ///
  /// In en, this message translates to:
  /// **'TAP FOR HELP'**
  String get tapForHelp;

  /// No description provided for @nAlerts.
  ///
  /// In en, this message translates to:
  /// **'{count} alert{count, plural, =1{} other{s}}'**
  String nAlerts(int count);

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500mg, 2 tablets'**
  String get dosageHint;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Take with food'**
  String get notesHint;

  /// No description provided for @enterMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Enter medicine name'**
  String get enterMedicineName;

  /// No description provided for @enterDosage.
  ///
  /// In en, this message translates to:
  /// **'Enter dosage'**
  String get enterDosage;

  /// No description provided for @onceDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get onceDailyLabel;

  /// No description provided for @twiceDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Twice daily'**
  String get twiceDailyLabel;

  /// No description provided for @weeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyLabel;

  /// No description provided for @asNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeededLabel;

  /// No description provided for @sosAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 SOS ALERT'**
  String get sosAlertTitle;

  /// No description provided for @emergencyAlertWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert will be sent in'**
  String get emergencyAlertWillBeSent;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @sosContactsWillReceiveSms.
  ///
  /// In en, this message translates to:
  /// **'Your emergency contacts will receive an SMS with your GPS location.'**
  String get sosContactsWillReceiveSms;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Stay Protected 24/7'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Safora monitors for emergencies, disasters, and safety threats — alerting your family instantly with your GPS location.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contacts'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 trusted contacts. When danger strikes, they\'ll get an instant SMS with your exact location and alert type.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Your Medical Profile'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Save your blood type, allergies, and medical conditions. First responders can access this info during emergencies.'**
  String get onboardingDesc3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @locationNeededSnack.
  ///
  /// In en, this message translates to:
  /// **'Location is needed for SOS. Enable in Settings.'**
  String get locationNeededSnack;

  /// No description provided for @notificationsNeededSnack.
  ///
  /// In en, this message translates to:
  /// **'Notifications are needed for alerts. Enable in Settings.'**
  String get notificationsNeededSnack;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Family\'s Safety Guardian'**
  String get appTagline;

  /// No description provided for @mAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String mAgo(int count);

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hAgo(int count);

  /// No description provided for @dAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String dAgo(int count);

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Require PIN or biometrics to open Safora'**
  String get appLockDesc;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterPinToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN to unlock'**
  String get enterPinToUnlock;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get wrongPin;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometric;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN'**
  String get setPinTitle;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSet;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics (fingerprint/face)'**
  String get biometricAuth;

  /// No description provided for @lockEnabled.
  ///
  /// In en, this message translates to:
  /// **'App lock enabled'**
  String get lockEnabled;

  /// No description provided for @lockDisabled.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get lockDisabled;

  /// No description provided for @changePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your security PIN'**
  String get changePinDesc;

  /// No description provided for @changePinSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get changePinSuccess;

  /// No description provided for @sosHistory.
  ///
  /// In en, this message translates to:
  /// **'SOS History'**
  String get sosHistory;

  /// No description provided for @sosHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'View past SOS activations'**
  String get sosHistoryDesc;

  /// No description provided for @noSosHistory.
  ///
  /// In en, this message translates to:
  /// **'No SOS history yet'**
  String get noSosHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all SOS history?'**
  String get historyClearConfirm;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'SOS history cleared'**
  String get historyCleared;

  /// No description provided for @triggerManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get triggerManual;

  /// No description provided for @triggerShake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get triggerShake;

  /// No description provided for @triggerCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash Detection'**
  String get triggerCrash;

  /// No description provided for @triggerBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get triggerBackground;

  /// No description provided for @contactsNotifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Contacts notified'**
  String get contactsNotifiedLabel;

  /// No description provided for @smsSentLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS sent'**
  String get smsSentLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @crashFallDetection.
  ///
  /// In en, this message translates to:
  /// **'Crash/Fall Detection'**
  String get crashFallDetection;

  /// No description provided for @crashFallDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect crashes and falls'**
  String get crashFallDetectionDesc;

  /// No description provided for @crashFallEnabled.
  ///
  /// In en, this message translates to:
  /// **'Crash/Fall detection enabled'**
  String get crashFallEnabled;

  /// No description provided for @crashFallDisabled.
  ///
  /// In en, this message translates to:
  /// **'Crash/Fall detection disabled'**
  String get crashFallDisabled;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @geofenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe Zone Geofence'**
  String get geofenceTitle;

  /// No description provided for @geofenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Alert when you leave all defined safe zones'**
  String get geofenceDesc;

  /// No description provided for @snatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Snatch Detection'**
  String get snatchTitle;

  /// No description provided for @snatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Detect phone grab attempts using motion sensors'**
  String get snatchDesc;

  /// No description provided for @speedAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Alert'**
  String get speedAlertTitle;

  /// No description provided for @speedAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Alert when traveling above 120 km/h'**
  String get speedAlertDesc;

  /// No description provided for @contextAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Context Alerts'**
  String get contextAlertTitle;

  /// No description provided for @contextAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered alerts for heat, drowsy driving, and more'**
  String get contextAlertDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
