class AppConstants {
  static const String appName = 'Dawn Weaver';
  static const String appVersion = '1.0.0';
  
  // Alarm constants
  static const int defaultSnoozeMinutes = 10;
  static const int maxSnoozeMinutes = 60;
  static const int minSnoozeMinutes = 1;
  
  // Content refresh intervals
  static const Duration contentRefreshInterval = Duration(hours: 24);
  static const Duration weatherRefreshInterval = Duration(hours: 1);
  
  // Audio settings
  static const double defaultSpeechRate = 0.5;
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;
  
  // Animation durations
  static const Duration pulseAnimationDuration = Duration(seconds: 2);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration slideAnimationDuration = Duration(milliseconds: 300);
  
  // Virtual character URLs (fallback)
  static const List<String> fallbackCharacterUrls = [
    'https://pixabay.com/get/ga9df13a5d2cf689e58e68edf783526d39a2001018b437ec4d2e7629c15620a75b5cc633a00d1402f3f2a90b89d3622cb8bb0dabbca0fd0462d08815067a2d479_1280.png',
    'https://pixabay.com/get/g67ab19fa3fc380b31ad231572f693eb6d5588ba32075e7db8c9a7cc4455cfe284894151b9ce33ff23ec5f87425fc6207d50b8b1ce92044859bcbe23bb2191303_1280.png',
    'https://pixabay.com/get/g00dc0a828f58e81b37f9a01c07d883a1e793db7eae671c368f3f929f55c3b66490ccbf05b6034ec1683383fe64e42dfdff311b0082adfe2a5e42a343d2a82d62_1280.png',
    'https://pixabay.com/get/g5378ee0dd82bcc2434d6d7331509931fd671c7b93071b5c469f1a0c1a87ca780d3474fe9471b32b17fceed2e803d3b9d3f34cb09b40732292e44f942d310f4f4_1280.jpg',
    'https://pixabay.com/get/g763cf1dc98ff285867614c3e429c1641d9e58a89e7149ccc05ad4cc4936661c59dbb898c82efaf00289e2b07ac53b0d612570fb060fd11dd52a2391b3be6adf1_1280.jpg',
    'https://pixabay.com/get/ga608ae14800f8b45e6fe940c1573a955cf6b6edd90bbc6b07fc223cf900b8bd3cf51fc3868a363fd033d6dda424c57a0777e308ba9587e0b4c0c155a69c9c8bb_1280.png',
  ];
  
  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
  };
  
  // Weather API
  static const String weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  // Notification channel
  static const String alarmChannelId = 'alarm_channel';
  static const String alarmChannelName = 'Alarms';
  static const String alarmChannelDescription = 'Dawn Weaver alarm notifications';
}

class LocalizationStrings {
  static const Map<String, Map<String, String>> strings = {
    'en': {
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'hello': 'Hello',
      'wake_up': 'Wake up!',
      'time_to_wake_up': 'Time to wake up!',
      'have_great_day': 'Have a great day!',
      'snooze': 'Snooze',
      'dismiss': 'Dismiss',
      'im_awake': "I'm Awake!",
      'next_alarm': 'Next Alarm',
      'no_active_alarms': 'No Active Alarms',
      'create_first_alarm': 'Tap + to create your first alarm',
      'motivational': 'Motivational Messages',
      'horoscope': 'Daily Horoscope',
      'weather': 'Weather Update',
      'virtual_character': 'Virtual Character',
      'alarm_time': 'Alarm Time',
      'repeat': 'Repeat',
      'once': 'Once',
      'daily': 'Daily',
      'weekdays': 'Weekdays',
      'weekends': 'Weekends',
    },
    'es': {
      'good_morning': 'Buenos Días',
      'good_afternoon': 'Buenas Tardes',
      'good_evening': 'Buenas Noches',
      'hello': 'Hola',
      'wake_up': '¡Despierta!',
      'time_to_wake_up': '¡Es hora de despertar!',
      'have_great_day': '¡Que tengas un gran día!',
      'snooze': 'Posponer',
      'dismiss': 'Descartar',
      'im_awake': '¡Estoy Despierto!',
      'next_alarm': 'Próxima Alarma',
      'no_active_alarms': 'No Hay Alarmas Activas',
      'create_first_alarm': 'Toca + para crear tu primera alarma',
      'motivational': 'Mensajes Motivacionales',
      'horoscope': 'Horóscopo Diario',
      'weather': 'Actualización del Clima',
      'virtual_character': 'Personaje Virtual',
      'alarm_time': 'Hora de Alarma',
      'repeat': 'Repetir',
      'once': 'Una Vez',
      'daily': 'Diario',
      'weekdays': 'Días Laborables',
      'weekends': 'Fines de Semana',
    },
  };
  
  static String get(String key, String language) {
    return strings[language]?[key] ?? strings['en']?[key] ?? key;
  }
}