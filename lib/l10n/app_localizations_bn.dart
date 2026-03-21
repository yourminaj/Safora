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
  String get liveMap => 'লাইভ ম্যাপ';

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
  String get maxContactsReached => 'ফ্রি প্ল্যানে সর্বোচ্চ ৩টি যোগাযোগ';

  @override
  String get incomingCall => 'ইনকামিং কল...';

  @override
  String get decline => 'প্রত্যাখ্যান';

  @override
  String get answer => 'উত্তর দিন';

  @override
  String get endCall => 'কল শেষ';

  @override
  String get mute => 'নীরব';

  @override
  String get keypad => 'কীপ্যাড';

  @override
  String get speaker => 'স্পিকার';

  @override
  String get settings => 'সেটিংস';

  @override
  String get shakeToSos => 'ঝাঁকালে SOS';

  @override
  String get shakeToSosDesc => 'SOS ট্রিগার করতে ফোন ৩ বার ঝাঁকান';

  @override
  String get lowBatteryWarning => 'কম ব্যাটারি সতর্কতা';

  @override
  String batteryAt(int level) {
    return 'আপনার ব্যাটারি $level%-এ আছে।';
  }
}
