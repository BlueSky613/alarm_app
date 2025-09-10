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

  UserProfile({
    this.name = 'Hello',
    this.zodiacSign = ZodiacSign.aries,
    this.weather = 'Celsius',
    this.horoscope = 'daily',
    this.language = 'en',
    this.firstTimeSetup = true,
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
      );

  UserProfile copyWith({
    String? name,
    ZodiacSign? zodiacSign,
    String? language,
    bool? firstTimeSetup,
    String? weather,
    String? horoscope,
  }) =>
      UserProfile(
        name: name ?? this.name,
        zodiacSign: zodiacSign ?? this.zodiacSign,
        language: language ?? this.language,
        firstTimeSetup: firstTimeSetup ?? this.firstTimeSetup,
        weather: weather ?? this.weather,
        horoscope: horoscope ?? this.horoscope,
      );
}
