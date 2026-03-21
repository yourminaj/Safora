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

  /// No description provided for @liveMap.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get liveMap;

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

  /// No description provided for @maxContactsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 contacts for free tier'**
  String get maxContactsReached;

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
