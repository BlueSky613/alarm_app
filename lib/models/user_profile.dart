enum ZodiacSign {
  aries, taurus, gemini, cancer, leo, virgo,
  libra, scorpio, sagittarius, capricorn, aquarius, pisces
}

class UserProfile {
  final String name;
  final ZodiacSign zodiacSign;
  final String language;
  final bool firstTimeSetup;

  UserProfile({
    required this.name,
    required this.zodiacSign,
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
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    zodiacSign: ZodiacSign.values.firstWhere(
      (e) => e.name == json['zodiacSign'],
      orElse: () => ZodiacSign.aries,
    ),
    language: json['language'] ?? 'en',
    firstTimeSetup: json['firstTimeSetup'] ?? true,
  );

  UserProfile copyWith({
    String? name,
    ZodiacSign? zodiacSign,
    String? language,
    bool? firstTimeSetup,
  }) => UserProfile(
    name: name ?? this.name,
    zodiacSign: zodiacSign ?? this.zodiacSign,
    language: language ?? this.language,
    firstTimeSetup: firstTimeSetup ?? this.firstTimeSetup,
  );
}