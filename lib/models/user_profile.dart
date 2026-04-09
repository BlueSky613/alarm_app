enum ZodiacSign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces
}

class UserProfile {
  final String name;
  final ZodiacSign zodiacSign;
  final String weather;
  final String horoscope;
  final String language;
  final bool firstTimeSetup;
  final String? solanaAddress;
  final double? solanaBalance;
  /// Local mirror of server `premium` (Pro) status.
  final bool isPremium;
  final bool hapticEnabled;
  final bool soundNotificationsEnabled;
  final double alarmVolume;
  /// `default` | `asset:assets/avatar/...` | `file:<absolute path>`
  final String avatarRef;

  UserProfile({
    this.name = 'Hello',
    this.zodiacSign = ZodiacSign.aries,
    this.weather = 'Celsius',
    this.horoscope = 'daily',
    this.language = 'en',
    this.firstTimeSetup = true,
    this.solanaAddress,
    this.solanaBalance,
    this.isPremium = false,
    this.hapticEnabled = true,
    this.soundNotificationsEnabled = true,
    this.alarmVolume = 0.8,
    this.avatarRef = 'default',
  });

  String get zodiacEmoji {
    const emojis = {
      ZodiacSign.aries: '♈',
      ZodiacSign.taurus: '♉',
      ZodiacSign.gemini: '♊',
      ZodiacSign.cancer: '♋',
      ZodiacSign.leo: '♌',
      ZodiacSign.virgo: '♍',
      ZodiacSign.libra: '♎',
      ZodiacSign.scorpio: '♏',
      ZodiacSign.sagittarius: '♐',
      ZodiacSign.capricorn: '♑',
      ZodiacSign.aquarius: '♒',
      ZodiacSign.pisces: '♓',
    };
    return emojis[zodiacSign]!;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'zodiacSign': zodiacSign.name,
        'language': language,
        'firstTimeSetup': firstTimeSetup,
        'weather': weather,
        'horoscope': horoscope,
        'solanaAddress': solanaAddress,
        'solanaBalance': solanaBalance,
        'isPremium': isPremium,
        'hapticEnabled': hapticEnabled,
        'soundNotificationsEnabled': soundNotificationsEnabled,
        'alarmVolume': alarmVolume,
        'avatarRef': avatarRef,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        zodiacSign: ZodiacSign.values.firstWhere(
          (e) => e.name == json['zodiacSign'],
          orElse: () => ZodiacSign.aries,
        ),
        language: json['language'] ?? 'en',
        firstTimeSetup: json['firstTimeSetup'] ?? true,
        weather: json['weather'] ?? 'Celsius',
        horoscope: json['horoscope'] ?? 'daily',
        solanaAddress: json['solanaAddress'] as String?,
        solanaBalance: (json['solanaBalance'] as num?)?.toDouble(),
        isPremium: json['isPremium'] as bool? ?? false,
        hapticEnabled: json['hapticEnabled'] as bool? ?? true,
        soundNotificationsEnabled:
            json['soundNotificationsEnabled'] as bool? ?? true,
        alarmVolume: (json['alarmVolume'] as num?)?.toDouble() ?? 0.8,
        avatarRef: json['avatarRef'] as String? ?? 'default',
      );

  UserProfile copyWith({
    String? name,
    ZodiacSign? zodiacSign,
    String? language,
    bool? firstTimeSetup,
    String? weather,
    String? horoscope,
    String? solanaAddress,
    double? solanaBalance,
    bool? isPremium,
    bool? hapticEnabled,
    bool? soundNotificationsEnabled,
    double? alarmVolume,
    String? avatarRef,
  }) =>
      UserProfile(
        name: name ?? this.name,
        zodiacSign: zodiacSign ?? this.zodiacSign,
        language: language ?? this.language,
        firstTimeSetup: firstTimeSetup ?? this.firstTimeSetup,
        weather: weather ?? this.weather,
        horoscope: horoscope ?? this.horoscope,
        solanaAddress: solanaAddress ?? this.solanaAddress,
        solanaBalance: solanaBalance ?? this.solanaBalance,
        isPremium: isPremium ?? this.isPremium,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        soundNotificationsEnabled:
            soundNotificationsEnabled ?? this.soundNotificationsEnabled,
        alarmVolume: alarmVolume ?? this.alarmVolume,
        avatarRef: avatarRef ?? this.avatarRef,
      );
}
