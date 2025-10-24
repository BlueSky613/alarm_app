import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Common
  String get appTitle;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get add;
  String get settings;
  String get back;

  // Language Settings
  String get language;
  String get spanish;
  String get english;
  String get selectLanguage;

  // User Setup
  String get welcome;
  String get enterYourName;
  String get name;
  String get pleaseEnterYourName;
  String get continue_;
  String get setupComplete;

  // Home Screen
  String get goodMorning;
  String get goodAfternoon;
  String get goodEvening;
  String get noAlarmsSet;
  String get addYourFirstAlarm;
  String get nextAlarm;

  // Alarms
  String get alarms;
  String get addAlarm;
  String get editAlarm;
  String get deleteAlarm;
  String get time;
  String get label;
  String get repeat;
  String get sound;
  String get enabled;
  String get disabled;
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;

  // Wake up Screen
  String get wakeUp;
  String goodMorningName(String name);
  String get stopAlarm;
  String get snooze;

  // Settings
  String get generalSettings;
  String get notifications;
  String get about;
  String get version;

  // Home Screen Extended
  String helloName(String name);
  String get quickAlarm;
  String get powerNap;
  String get minutes15;
  String get minutes20;
  String get profile;
  String get noActiveAlarms;
  String get tapToCreateFirstAlarm;
  String get nextAlarmIn;
  String get inTime;
  String quickAlarmSetFor(String time);

  // Alarm Management
  String get alarmList;
  String get noAlarmsYet;
  String get createFirstAlarm;
  String get activeAlarms;
  String get inactiveAlarms;
  String get alarmDeleted;
  String get alarmSaved;
  String get selectTime;
  String get alarmLabel;
  String get enterLabel;
  String get repeatDays;
  String get selectDays;
  String get alarmTone;
  String get selectTone;
  String get vibration;
  String get snoozeEnabled;
  String get motivationalMessage;
  String get weatherInfo;
  String get horoscope;
  String get virtualCharacter;

  // Days of week (short)
  String get mon;
  String get tue;
  String get wed;
  String get thu;
  String get fri;
  String get sat;
  String get sun;

  // Wake up Screen Extended
  String get dismissAlarm;
  String get snooze5min;
  String get snooze10min;
  String get alarmStopped;
  String get snoozedFor;
  String snoozedForMinutes(int minutes);
  String get awake;

  // Common Actions
  String get confirm;
  String get dismiss;
  String get retry;
  String get close;
  String get next;
  String get previous;
  String get done;
  String get skip;

  // Error Messages
  String get error;
  String get errorOccurred;
  String get tryAgain;
  String get noInternetConnection;
  String get failedToLoad;
  String get invalidInput;
  String get permissionDenied;

  // Success Messages
  String get success;
  String get savedSuccessfully;
  String get deletedSuccessfully;
  String get updatedSuccessfully;

  // Time and Date
  String get today;
  String get tomorrow;
  String get yesterday;
  String get now;
  String get am;
  String get pm;

  // Settings Extended
  String get profileSettings;
  String get alarmSettings;
  String get soundSettings;
  String get displaySettings;
  String get privacySettings;
  String get helpSupport;
  String get rateApp;
  String get shareApp;
  String get contactUs;
  String get termsOfService;
  String get privacyPolicy;
  String get clearAllData;
  String get dangerZone;
  String get confirmClearData;
  String get clearDataWarning;
  String get deleteEverything;
  String get cannotBeUndone;

  // User Profile
  String get editProfile;
  String get changeName;
  String get changeZodiacSign;
  String get selectZodiacSign;
  String get profileUpdated;
  String get nameRequired;

  // Permissions and Notifications
  String get notificationPermission;
  String get allowNotifications;
  String get audioSettings;
  String get manageAudio;
  String get goToSettings;
  String get openDeviceSettings;

  // Language helpers
  bool get isSpanish;
  bool get isEnglish;
}
