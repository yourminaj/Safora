// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'সাফোরা SOS';

  @override
  String get allSafe => 'সব নিরাপদ';

  @override
  String get noActiveThreats => 'কোনো সক্রিয় হুমকি সনাক্ত হয়নি';

  @override
  String get live => 'লাইভ';

  @override
  String get tapToViewDetails => 'বিস্তারিত দেখতে ট্যাপ করুন';

  @override
  String activeAlerts(int count) {
    return '$countটি সক্রিয় সতর্কতা';
  }

  @override
  String get sosButton => 'SOS';

  @override
  String sosCountdown(int seconds) {
    return '$seconds সেকেন্ডে SOS';
  }

  @override
  String get sosActive => 'SOS সতর্কতা সক্রিয়';

  @override
  String get sosCancelled => 'SOS বাতিল হয়েছে';

  @override
  String get tapToCancel => 'বাতিল করতে ট্যাপ করুন';

  @override
  String get quickActions => 'দ্রুত কার্যক্রম';

  @override
  String get decoyCall => 'ডিকয় কল';

  @override
  String get contacts => 'যোগাযোগ';

  @override
  String get medicalId => 'মেডিকেল আইডি';

  @override
  String get alerts => 'সতর্কতা';

  @override
  String get alertMap => 'সতর্কতা ম্যাপ';

  @override
  String get reminders => 'রিমাইন্ডার';

  @override
  String get recentAlerts => 'সাম্প্রতিক সতর্কতা';

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get noRecentAlerts => 'কোনো সাম্প্রতিক সতর্কতা নেই';

  @override
  String get allClear => 'সব ঠিক আছে!';

  @override
  String get noActiveAlerts =>
      'আপনার এলাকায় কোনো সক্রিয় সতর্কতা নেই। আমরা ১২৭ ধরনের ঝুঁকি পর্যবেক্ষণ করি।';

  @override
  String get disasterAlerts => 'দুর্যোগ সতর্কতা';

  @override
  String get filterAll => 'সব';

  @override
  String get filterCritical => 'জরুরি';

  @override
  String get filterDisaster => 'দুর্যোগ';

  @override
  String get filterWeather => 'আবহাওয়া';

  @override
  String get filterWater => 'পানি';

  @override
  String get autoRefreshNote => 'প্রতি ১৫ মিনিটে স্বয়ংক্রিয় রিফ্রেশ';

  @override
  String get unableToLoadAlerts => 'সতর্কতা লোড করা যায়নি';

  @override
  String get checkConnection =>
      'আপনার ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get retry => 'পুনরায় চেষ্টা';

  @override
  String get medicalProfile => 'মেডিকেল প্রোফাইল';

  @override
  String get editMedicalProfile => 'মেডিকেল প্রোফাইল সম্পাদনা';

  @override
  String get createMedicalProfile => 'মেডিকেল প্রোফাইল তৈরি';

  @override
  String get noMedicalProfile => 'কোনো মেডিকেল প্রোফাইল নেই';

  @override
  String get createProfileHint =>
      'আপনার মেডিকেল প্রোফাইল তৈরি করুন যাতে জরুরি সেবাদানকারীরা আপনার গুরুত্বপূর্ণ তথ্য পেতে পারে।';

  @override
  String get createProfile => 'প্রোফাইল তৈরি';

  @override
  String get fullName => 'পুরো নাম';

  @override
  String get bloodType => 'রক্তের গ্রুপ';

  @override
  String get allergies => 'অ্যালার্জি';

  @override
  String get medicalConditions => 'চিকিৎসা অবস্থা';

  @override
  String get medications => 'ওষুধ';

  @override
  String get emergencyNotes => 'জরুরি নোট';

  @override
  String get weight => 'ওজন (কেজি)';

  @override
  String get height => 'উচ্চতা (সেমি)';

  @override
  String get organDonor => 'অঙ্গ দাতা';

  @override
  String get shareWithFirstResponders => 'উদ্ধারকারীদের সাথে শেয়ার করুন';

  @override
  String get separateWithCommas => 'কমা দিয়ে আলাদা করুন';

  @override
  String get nameRequired => 'নাম প্রয়োজন';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get notSet => 'সেট করা হয়নি';

  @override
  String get noneListed => 'কিছু তালিকাভুক্ত নেই';

  @override
  String get emergencyContacts => 'জরুরি যোগাযোগ';

  @override
  String get addContact => 'যোগাযোগ যোগ করুন';

  @override
  String get editContact => 'যোগাযোগ সম্পাদনা';

  @override
  String get contactDetails => 'যোগাযোগের বিবরণ';

  @override
  String get setAsPrimaryContact => 'প্রাথমিক যোগাযোগ হিসেবে সেট করুন';

  @override
  String get maxContactsReached => 'ফ্রি প্ল্যানে সর্বোচ্চ ৩টি যোগাযোগ';

  @override
  String get contactLimitReached => 'যোগাযোগ সীমা পূর্ণ';

  @override
  String get contactLimitMessage =>
      'ফ্রি ব্যবহারকারীরা সর্বোচ্চ ৩টি জরুরি যোগাযোগ যোগ করতে পারবেন।';

  @override
  String get premiumRoadmap =>
      'প্রিমিয়াম ফিচার সহ সীমাহীন যোগাযোগ, সব ১২৭ ধরনের ঝুঁকি, এবং উন্নত সনাক্তকরণ শীঘ্রই আসছে।';

  @override
  String get removeContact => 'যোগাযোগ মুছবেন?';

  @override
  String removeContactConfirm(String name) {
    return 'আপনি কি নিশ্চিত $name-কে আপনার জরুরি যোগাযোগ থেকে মুছতে চান?';
  }

  @override
  String get cancel => 'বাতিল';

  @override
  String get remove => 'মুছুন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get setAsPrimary => 'প্রাথমিক সেট করুন';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get primary => 'প্রাথমিক';

  @override
  String nContactsAdded(int count) {
    return '$countটি যোগাযোগ যোগ করা হয়েছে';
  }

  @override
  String get noEmergencyContacts => 'কোনো জরুরি যোগাযোগ নেই';

  @override
  String get addContactsHint =>
      'জরুরি সময় আপনার GPS লোকেশনসহ সতর্ক করার জন্য ৩ জন বিশ্বস্ত ব্যক্তি যোগ করুন।';

  @override
  String get incomingCall => 'ইনকামিং কল...';

  @override
  String get decline => 'প্রত্যাখ্যান';

  @override
  String get answer => 'উত্তর দিন';

  @override
  String get endCall => 'কল শেষ';

  @override
  String get mute => 'মিউট';

  @override
  String get keypad => 'কীপ্যাড';

  @override
  String get speaker => 'স্পিকার';

  @override
  String get settings => 'সেটিংস';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get manageProfile => 'আপনার মেডিকেল প্রোফাইল পরিচালনা';

  @override
  String get premium => 'প্রিমিয়াম';

  @override
  String get unlockAllRiskTypes => 'সব ১২৭ ধরনের ঝুঁকি আনলক করুন';

  @override
  String get saforaPremium => 'সাফোরা প্রিমিয়াম';

  @override
  String get currentFreePlan => 'বর্তমান ফ্রি প্ল্যানে আছে:';

  @override
  String get freeSos => '✅ SMS সতর্কতাসহ SOS';

  @override
  String get freeContacts => '✅ ৩টি জরুরি যোগাযোগ';

  @override
  String get freeAlerts => '✅ রিয়েল-টাইম দুর্যোগ সতর্কতা';

  @override
  String get freeDetection => '✅ দুর্ঘটনা ও পতন সনাক্তকরণ';

  @override
  String get freeMedicalId => '✅ মেডিকেল আইডি প্রোফাইল';

  @override
  String get pro => 'প্রো';

  @override
  String get safety => 'নিরাপত্তা';

  @override
  String get shakeToSos => 'ঝাঁকালে SOS';

  @override
  String get shakeToSosDesc => 'SOS ট্রিগার করতে ফোন ৩ বার ঝাঁকান';

  @override
  String get alertSounds => 'সতর্কতা শব্দ';

  @override
  String get configureAlertSounds => 'সতর্কতা শব্দ কনফিগার করুন';

  @override
  String get alertSoundSettings => 'সতর্কতা শব্দ সেটিংস';

  @override
  String get alertSoundExplain =>
      'সতর্কতা শব্দ অগ্রাধিকার অনুযায়ী স্বয়ংক্রিয়ভাবে কনফিগার করা হয়:';

  @override
  String get criticalSiren => '🔴 জটিল — জরুরি সাইরেন';

  @override
  String get highMediumWarning => '🟡 উচ্চ / মাঝারি — সতর্কতা টোন';

  @override
  String get lowNotification => '🟢 নিম্ন — মৃদু বিজ্ঞপ্তি';

  @override
  String get customSoundFuture =>
      'কাস্টম শব্দ নির্বাচন ভবিষ্যত আপডেটে পাওয়া যাবে।';

  @override
  String get general => 'সাধারণ';

  @override
  String get language => 'ভাষা';

  @override
  String get english => 'ইংরেজি';

  @override
  String get languageSettings => 'ভাষা সেটিংস';

  @override
  String get languageExplain =>
      'সাফোরা ইংরেজি এবং বাংলা সমর্থন করে। অ্যাপের ভাষা আপনার ডিভাইসের ভাষা সেটিং অনুসারে স্বয়ংক্রিয়ভাবে পরিবর্তন হয়।';

  @override
  String get toChangeLanguage => 'ভাষা পরিবর্তন করতে যান:';

  @override
  String get deviceSettingsLanguage => '📱 ডিভাইস সেটিংস → ভাষা ও অঞ্চল';

  @override
  String get inAppLanguageFuture =>
      'অ্যাপের মধ্যে ভাষা পরিবর্তন ভবিষ্যত আপডেটে পাওয়া যাবে।';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get systemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get themeFollowsSystem => 'থিম সিস্টেম সেটিংস অনুসারে';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get saforaVersion => 'সাফোরা v০.১.০';

  @override
  String get saforaLegalese => '© ২০২৬ সাফোরা টেকনোলজিস';

  @override
  String get saforaAbout =>
      'আপনার পরিবারের নিরাপত্তা অভিভাবক — রিয়েল-টাইম দুর্যোগ সতর্কতা, SOS, এবং জরুরি বিজ্ঞপ্তি দিয়ে আপনাকে সুরক্ষিত রাখে।';

  @override
  String get medicineReminders => '💊 ওষুধের রিমাইন্ডার';

  @override
  String nActive(int count) {
    return '$countটি সক্রিয়';
  }

  @override
  String get noRemindersSet => 'কোনো রিমাইন্ডার সেট করা হয়নি';

  @override
  String get addRemindersHint =>
      'সময়মতো বিজ্ঞপ্তি পেতে ওষুধের\nরিমাইন্ডার যোগ করুন';

  @override
  String get lowBatteryWarning => 'কম ব্যাটারি সতর্কতা';

  @override
  String batteryAt(int level) {
    return 'আপনার ব্যাটারি $level%-এ আছে।';
  }

  @override
  String get pageNotFound => 'পৃষ্ঠা পাওয়া যায়নি';

  @override
  String routeNotFound(String route) {
    return 'রুট পাওয়া যায়নি: $route';
  }

  @override
  String get goHome => 'হোমে যান';

  @override
  String get somethingWentWrong => 'কিছু ভুল হয়েছে';

  @override
  String get phoneNumber => 'ফোন নম্বর';

  @override
  String get relationship => 'সম্পর্ক (ঐচ্ছিক)';

  @override
  String get relationshipHint => 'যেমন মা, ভাই, বন্ধু';

  @override
  String get enterName => 'একটি নাম দিন';

  @override
  String get enterPhone => 'একটি ফোন নম্বর দিন';

  @override
  String get enterValidPhone => 'একটি সঠিক ফোন নম্বর দিন';

  @override
  String get primaryContactNotify =>
      'জরুরি সময় এই ব্যক্তিকে প্রথমে জানানো হবে।';

  @override
  String get sosAlertActivated => '🚨 SOS সতর্কতা সক্রিয়! সাইরেন বাজছে।';

  @override
  String get stop => 'বন্ধ করুন';

  @override
  String get tapForHelp => 'সাহায্যের জন্য ট্যাপ করুন';

  @override
  String nAlerts(int count) {
    return '$countটি সতর্কতা';
  }

  @override
  String get addReminder => 'রিমাইন্ডার যোগ করুন';

  @override
  String get medicineName => 'ওষুধের নাম';

  @override
  String get dosage => 'ডোজ';

  @override
  String get dosageHint => 'যেমন ৫০০ মিগ্রা, ২ ট্যাবলেট';

  @override
  String get time => 'সময়';

  @override
  String get frequency => 'ফ্রিকোয়েন্সি';

  @override
  String get notes => 'নোট (ঐচ্ছিক)';

  @override
  String get notesHint => 'যেমন খাবারের সাথে খান';

  @override
  String get enterMedicineName => 'ওষুধের নাম দিন';

  @override
  String get enterDosage => 'ডোজ দিন';

  @override
  String get onceDailyLabel => 'দিনে একবার';

  @override
  String get twiceDailyLabel => 'দিনে দুইবার';

  @override
  String get weeklyLabel => 'সাপ্তাহিক';

  @override
  String get asNeededLabel => 'প্রয়োজন অনুযায়ী';

  @override
  String get sosAlertTitle => '🚨 এসওএস সতর্কতা';

  @override
  String get emergencyAlertWillBeSent => 'জরুরি সতর্কতা পাঠানো হবে';

  @override
  String get seconds => 'সেকেন্ড';

  @override
  String get sosContactsWillReceiveSms =>
      'আপনার জরুরি যোগাযোগকারীরা আপনার জিপিএস অবস্থান সহ একটি এসএমএস পাবেন।';

  @override
  String get onboardingTitle1 => '২৪/৭ সুরক্ষিত থাকুন';

  @override
  String get onboardingDesc1 =>
      'সাফোরা জরুরি অবস্থা, দুর্যোগ এবং নিরাপত্তা হুমকি পর্যবেক্ষণ করে — আপনার জিপিএস অবস্থান সহ তাৎক্ষণিকভাবে আপনার পরিবারকে সতর্ক করে।';

  @override
  String get onboardingTitle2 => 'জরুরি যোগাযোগ যোগ করুন';

  @override
  String get onboardingDesc2 =>
      '৩ জন বিশ্বস্ত যোগাযোগ যোগ করুন। বিপদের সময় তারা আপনার সঠিক অবস্থান এবং সতর্কতার ধরন সহ তাৎক্ষণিক এসএমএস পাবেন।';

  @override
  String get onboardingTitle3 => 'আপনার মেডিকেল প্রোফাইল';

  @override
  String get onboardingDesc3 =>
      'আপনার রক্তের গ্রুপ, অ্যালার্জি এবং চিকিৎসা অবস্থা সংরক্ষণ করুন। জরুরি অবস্থায় প্রথম সাড়াদানকারীরা এই তথ্য ব্যবহার করতে পারবেন।';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get next => 'পরবর্তী';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get locationNeededSnack =>
      'এসওএস-এর জন্য অবস্থান প্রয়োজন। সেটিংসে সক্রিয় করুন।';

  @override
  String get notificationsNeededSnack =>
      'সতর্কতার জন্য নোটিফিকেশন প্রয়োজন। সেটিংসে সক্রিয় করুন।';

  @override
  String get appTagline => 'আপনার পরিবারের নিরাপত্তা অভিভাবক';

  @override
  String mAgo(int count) {
    return '$count মিনিট আগে';
  }

  @override
  String hAgo(int count) {
    return '$count ঘণ্টা আগে';
  }

  @override
  String dAgo(int count) {
    return '$count দিন আগে';
  }
}
