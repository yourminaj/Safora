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
  String get bodyInfo => 'শরীর';

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
  String get freeSos => 'SMS সতর্কতাসহ SOS';

  @override
  String get freeContacts => '৩টি জরুরি যোগাযোগ';

  @override
  String get freeAlerts => 'রিয়েল-টাইম দুর্যোগ সতর্কতা';

  @override
  String get freeDetection => 'দুর্ঘটনা ও পতন সনাক্তকরণ';

  @override
  String get freeMedicalId => 'মেডিকেল আইডি প্রোফাইল';

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
  String get criticalSiren => 'জটিল — জরুরি সাইরেন';

  @override
  String get highMediumWarning => 'উচ্চ / মাঝারি — সতর্কতা টোন';

  @override
  String get lowNotification => 'নিম্ন — মৃদু বিজ্ঞপ্তি';

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
  String get deviceSettingsLanguage => 'ডিভাইস সেটিংস → ভাষা ও অঞ্চল';

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
  String get saforaLegalese => '© ২০২৬ সাফোরা টেকনোলজিস';

  @override
  String get saforaAbout =>
      'আপনার পরিবারের নিরাপত্তা অভিভাবক — রিয়েল-টাইম দুর্যোগ সতর্কতা, SOS, এবং জরুরি বিজ্ঞপ্তি দিয়ে আপনাকে সুরক্ষিত রাখে।';

  @override
  String get medicineReminders => 'ওষুধের রিমাইন্ডার';

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
  String get somethingWentWrong => 'কিছু একটা সমস্যা হয়েছে';

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
  String get sosAlertActivated => 'SOS সতর্কতা সক্রিয়! সাইরেন বাজছে।';

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
  String get sosAlertTitle => 'এসওএস সতর্কতা';

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

  @override
  String get appLock => 'অ্যাপ লক';

  @override
  String get appLockDesc => 'সাফোরা খুলতে পিন বা বায়োমেট্রিক্স প্রয়োজন';

  @override
  String get enterPin => 'পিন দিন';

  @override
  String get enterPinToUnlock => 'আনলক করতে আপনার ৪-সংখ্যার পিন দিন';

  @override
  String get wrongPin => 'ভুল পিন। আবার চেষ্টা করুন।';

  @override
  String get useBiometric => 'বায়োমেট্রিক্স ব্যবহার করুন';

  @override
  String get setPinTitle => 'একটি ৪-সংখ্যার পিন সেট করুন';

  @override
  String get confirmPin => 'আপনার পিন নিশ্চিত করুন';

  @override
  String get pinMismatch => 'পিন মিলছে না। আবার চেষ্টা করুন।';

  @override
  String get pinSet => 'পিন সফলভাবে সেট হয়েছে';

  @override
  String get changePinTitle => 'পিন পরিবর্তন করুন';

  @override
  String get biometricAuth => 'বায়োমেট্রিক্স ব্যবহার করুন (আঙুলের ছাপ/মুখ)';

  @override
  String get lockEnabled => 'অ্যাপ লক সক্রিয়';

  @override
  String get lockDisabled => 'অ্যাপ লক নিষ্ক্রিয়';

  @override
  String get changePinDesc => 'আপনার সুরক্ষা পিন আপডেট করুন';

  @override
  String get changePinSuccess => 'পিন সফলভাবে পরিবর্তিত হয়েছে';

  @override
  String get sosHistory => 'SOS ইতিহাস';

  @override
  String get sosHistoryDesc => 'আগের SOS সক্রিয়করণ দেখুন';

  @override
  String get noSosHistory => 'এখনো কোনো SOS ইতিহাস নেই';

  @override
  String get clearHistory => 'ইতিহাস মুছুন';

  @override
  String get historyClearConfirm => 'আপনি কি সমস্ত SOS ইতিহাস মুছতে চান?';

  @override
  String get historyCleared => 'SOS ইতিহাস মোছা হয়েছে';

  @override
  String get triggerManual => 'ম্যানুয়াল';

  @override
  String get triggerShake => 'শেক';

  @override
  String get triggerCrash => 'ক্র্যাশ সনাক্তকরণ';

  @override
  String get triggerBackground => 'ব্যাকগ্রাউন্ড';

  @override
  String get contactsNotifiedLabel => 'যোগাযোগকৃত ব্যক্তি';

  @override
  String get smsSentLabel => 'SMS পাঠানো হয়েছে';

  @override
  String get cancelledLabel => 'বাতিলকৃত';

  @override
  String get completedLabel => 'সম্পন্ন';

  @override
  String get crashFallDetection => 'ক্র্যাশ/পতন সনাক্তকরণ';

  @override
  String get crashFallDetectionDesc =>
      'ক্র্যাশ এবং পতন স্বয়ংক্রিয়ভাবে সনাক্ত করুন';

  @override
  String get crashFallEnabled => 'ক্র্যাশ/পতন সনাক্তকরণ সক্রিয়';

  @override
  String get crashFallDisabled => 'ক্র্যাশ/পতন সনাক্তকরণ নিষ্ক্রিয়';

  @override
  String get sensitivitySettings => 'সনাক্তকরণ সংবেদনশীলতা';

  @override
  String get fallThreshold => 'পতন থ্রেশহোল্ড (জি-ফোর্স)';

  @override
  String get crashThreshold => 'ক্র্যাশ থ্রেশহোল্ড (জি-ফোর্স)';

  @override
  String get minConfidence => 'ন্যূনতম আস্থা (%)';

  @override
  String get sensitivitySaved => 'সংবেদনশীলতা সেটিংস সংরক্ষিত';

  @override
  String get resetDefaults => 'ডিফল্ট রিসেট';

  @override
  String get themeSystem => 'সিস্টেম ডিফল্ট';

  @override
  String get themeLight => 'হালকা';

  @override
  String get themeDark => 'গাঢ়';

  @override
  String get chooseTheme => 'থিম বেছে নিন';

  @override
  String get geofenceTitle => 'নিরাপদ অঞ্চল জিওফেন্স';

  @override
  String get geofenceDesc => 'নিরাপদ অঞ্চল ত্যাগ করলে সতর্ক করুন';

  @override
  String get snatchTitle => 'ছিনতাই সনাক্তকরণ';

  @override
  String get snatchDesc => 'মোশন সেন্সর ব্যবহার করে ফোন ছিনতাই সনাক্ত করুন';

  @override
  String get speedAlertTitle => 'গতি সতর্কতা';

  @override
  String get speedAlertDesc => '১২০ কিমি/ঘণ্টার বেশি গতিতে সতর্ক করুন';

  @override
  String get contextAlertTitle => 'স্মার্ট প্রসঙ্গ সতর্কতা';

  @override
  String get contextAlertDesc =>
      'তাপ, তন্দ্রাচ্ছন্ন ড্রাইভিং এবং আরও অনেক কিছুর জন্য AI-চালিত সতর্কতা';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get signOutConfirm => 'আপনি কি সাইন আউট করতে চান?';

  @override
  String get createAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signInSubtitle => 'আপনার পরিচিতিগুলো ক্লাউডে সিঙ্ক করুন';

  @override
  String get resetPassword => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get send => 'পাঠান';

  @override
  String get noContactsInCloud => 'ক্লাউডে কোনো পরিচিতি পাওয়া যায়নি';

  @override
  String get syncFailed => 'সিঙ্ক ব্যর্থ হয়েছে';

  @override
  String get backupToCloud => 'ক্লাউডে ব্যাকআপ';

  @override
  String get restoreFromCloud => 'ক্লাউড থেকে পুনরুদ্ধার';

  @override
  String get filterHigh => 'উচ্চ';

  @override
  String get filterMedium => 'মাঝারি';

  @override
  String get filterLow => 'নিম্ন';

  @override
  String get filterSafety => 'নিরাপত্তা';

  @override
  String get filterHealth => 'স্বাস্থ্য';

  @override
  String get filterVehicle => 'যানবাহন';

  @override
  String get filterEnvironmental => 'পরিবেশগত';

  @override
  String get sosPreparingTitle => 'SOS প্রস্তুত হচ্ছে';

  @override
  String get sosPreflightChecks => 'প্রি-ফ্লাইট চেক চলছে...';

  @override
  String get preflightGps => 'জিপিএস অবস্থান';

  @override
  String get preflightNetwork => 'নেটওয়ার্ক';

  @override
  String get preflightContacts => 'জরুরি যোগাযোগ';

  @override
  String get preflightNoContacts =>
      'কোনো জরুরি যোগাযোগ কনফিগার করা হয়নি। SOS ব্যবহার করতে সেটিংসে অন্তত একটি যোগাযোগ যোগ করুন।';

  @override
  String get loadingAlerts => 'সতর্কতা লোড হচ্ছে...';

  @override
  String get preflightNoGps =>
      'জিপিএস অবস্থান পাওয়া যাচ্ছে না। সুনির্দিষ্ট স্থানাঙ্ক ছাড়াই SOS চালু হবে।';

  @override
  String get preflightNoNetwork =>
      'নেটওয়ার্ক সংযোগ নেই। সেলুলার উপলব্ধ থাকলে SMS সতর্কতা পাঠানো হবে।';

  @override
  String alertGeofenceExitTitle(String zone) {
    return 'নিরাপদ অঞ্চল ত্যাগ: $zone';
  }

  @override
  String alertGeofenceExitDesc(String zone) {
    return 'আপনি \"$zone\" নিরাপদ অঞ্চল ত্যাগ করেছেন। আপনার জরুরি পরিচিতিদের জানানো হয়েছে।';
  }

  @override
  String get alertSnatchTitle => 'ফোন ছিনতাই শনাক্ত';

  @override
  String alertSnatchDesc(String pct) {
    return 'হঠাৎ দিকনির্দেশক টান শনাক্ত হয়েছে (আত্মবিশ্বাস: $pct%)। SOS কাউন্টডাউন শুরু হয়েছে।';
  }

  @override
  String alertSpeedTitle(String speed) {
    return 'অতিরিক্ত গতি: $speed km/h';
  }

  @override
  String alertSpeedDesc(String speed) {
    return 'আপনার গতি নিরাপদ সীমা অতিক্রম করেছে ($speed km/h)। ধীর করুন।';
  }

  @override
  String get ctxHeatTitle => 'হিট স্ট্রোকের ঝুঁকি';

  @override
  String ctxHeatMsg(String temp) {
    return 'তাপমাত্রা $temp°C এবং আপনি বাইরে সক্রিয়। পানি পান করুন এবং ছায়ায় যান।';
  }

  @override
  String get ctxHypothermiaTitle => 'হাইপোথার্মিয়ার ঝুঁকি';

  @override
  String ctxHypothermiaMsg(String temp, String chill) {
    return 'তাপমাত্রা: $temp°C, উইন্ড চিল: $chill°C। অবিলম্বে উষ্ণ আশ্রয়ে যান।';
  }

  @override
  String get ctxDrowsyTitle => 'ঘুমন্ত ড্রাইভিং সতর্কতা';

  @override
  String ctxDrowsyMsg(String time, String speed) {
    return 'এখন $time এবং আপনি $speed km/h গতিতে চলছেন। বিশ্রামের জন্য থামুন।';
  }

  @override
  String get ctxNightWalkTitle => 'রাতে একা হাঁটা';

  @override
  String get ctxNightWalkMsg =>
      'আপনি রাতে একা হাঁটছেন। বিশ্বস্ত পরিচিতির সাথে লাইভ অবস্থান শেয়ার করুন। Safora SOS প্রস্তুত।';

  @override
  String get ctxAltitudeTitle => 'দ্রুত উচ্চতা পরিবর্তন';

  @override
  String ctxAltitudeMsg(String meters, String minutes) {
    return '$minutes মিনিটে ${meters}m উচ্চতা বৃদ্ধি। লক্ষণ দেখুন: মাথাব্যথা, বমি, মাথা ঘোরা।';
  }

  @override
  String get ctxFloodTitle => 'ফ্ল্যাশ ফ্লাডের ঝুঁকি';

  @override
  String ctxFloodMsg(String mm, String alt) {
    return 'ভারী বৃষ্টিপাত (${mm}mm) পূর্বাভাস এবং আপনি নিচু উচ্চতায় (${alt}m)। উঁচু জায়গায় যান।';
  }

  @override
  String get liveMap => 'লাইভ ম্যাপ';

  @override
  String get myLocation => 'আমার অবস্থান';

  @override
  String get safeZones => 'নিরাপদ অঞ্চল';

  @override
  String get showSafeZones => 'নিরাপদ অঞ্চল দেখান';

  @override
  String get hideSafeZones => 'নিরাপদ অঞ্চল লুকান';

  @override
  String get locationUnavailable => 'অবস্থান অনুপলব্ধ';

  @override
  String get more => 'আরো';

  @override
  String get safetyTools => 'নিরাপত্তা টুলস';

  @override
  String get profileSubtitle => 'আপনার ব্যক্তিগত তথ্য';

  @override
  String get settingsSubtitle => 'অ্যাপ পছন্দ ও সনাক্তকরণ';

  @override
  String get decoyCallSubtitle => 'ইনকামিং কল অনুকরণ করুন';

  @override
  String get remindersSubtitle => 'ওষুধ ও নিরাপত্তা রিমাইন্ডার';

  @override
  String get sosHistorySubtitle => 'পূর্ববর্তী SOS ইভেন্ট ও ফলাফল';

  @override
  String get alertMapSubtitle => 'মানচিত্রে সতর্কতা দেখুন';

  @override
  String get aboutSafora => 'Safora সম্পর্কে';

  @override
  String get aboutSaforaSubtitle => 'সংস্করণ তথ্য ও ক্রেডিট';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get remindersAccessedFromHome =>
      'রিমাইন্ডার হোম স্ক্রিন থেকে অ্যাক্সেস করা যায়';

  @override
  String get proFeatureTitle => 'প্রো ফিচার';

  @override
  String get proFeatureMessage =>
      'এই ফিচারটি সাফোরা প্রো প্রয়োজন। উন্নত সনাক্তকরণ, সীমাহীন যোগাযোগ এবং বিজ্ঞাপনমুক্ত অভিজ্ঞতা আনলক করতে আপগ্রেড করুন।';

  @override
  String get upgradeToPro => 'প্রো-তে আপগ্রেড করুন';

  @override
  String get sosHistoryFreeNote =>
      'শেষ ৭ দিন দেখানো হচ্ছে। সম্পূর্ণ ইতিহাসের জন্য প্রো-তে আপগ্রেড করুন।';
}
