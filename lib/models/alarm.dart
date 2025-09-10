class Alarms {
  final String id;
  final DateTime time;
  final bool isActive;
  final String label;
  final Set<int> repeatDays; // 0=Sunday, 1=Monday, etc.
  final String soundPath;
  final bool hasHoroscope;
  final bool hasMotivation;
  final bool hasWeather;
  final String virtualCharacter;
  final int snoozeMinutes;

  Alarms({
    required this.id,
    required this.time,
    this.isActive = true,
    this.label = '',
    this.repeatDays = const {},
    this.soundPath = 'default',
    this.hasHoroscope = false,
    this.hasMotivation = true,
    this.hasWeather = false,
    this.virtualCharacter = 'default',
    this.snoozeMinutes = 10,
  });

  bool get isRepeating => repeatDays.isNotEmpty;

  String get repeatString {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Daily';
    if (repeatDays.length == 5 && !repeatDays.contains(0) && !repeatDays.contains(6)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.contains(0) && repeatDays.contains(6)) {
      return 'Weekends';
    }
    
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return repeatDays.map((day) => days[day]).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toIso8601String(),
    'isActive': isActive,
    'label': label,
    'repeatDays': repeatDays.toList(),
    'soundPath': soundPath,
    'hasHoroscope': hasHoroscope,
    'hasMotivation': hasMotivation,
    'hasWeather': hasWeather,
    'virtualCharacter': virtualCharacter,
    'snoozeMinutes': snoozeMinutes,
  };

  factory Alarms.fromJson(Map<String, dynamic> json) => Alarms(
    id: json['id'],
    time: DateTime.parse(json['time']),
    isActive: json['isActive'] ?? true,
    label: json['label'] ?? '',
    repeatDays: Set<int>.from(json['repeatDays'] ?? []),
    soundPath: json['soundPath'] ?? 'default',
    hasHoroscope: json['hasHoroscope'] ?? false,
    hasMotivation: json['hasMotivation'] ?? true,
    hasWeather: json['hasWeather'] ?? false,
    virtualCharacter: json['virtualCharacter'] ?? 'default',
    snoozeMinutes: json['snoozeMinutes'] ?? 10,
  );

  Alarms copyWith({
    String? id,
    DateTime? time,
    bool? isActive,
    String? label,
    Set<int>? repeatDays,
    String? soundPath,
    bool? hasHoroscope,
    bool? hasMotivation,
    bool? hasWeather,
    String? virtualCharacter,
    int? snoozeMinutes,
  }) => Alarms(
    id: id ?? this.id,
    time: time ?? this.time,
    isActive: isActive ?? this.isActive,
    label: label ?? this.label,
    repeatDays: repeatDays ?? this.repeatDays,
    soundPath: soundPath ?? this.soundPath,
    hasHoroscope: hasHoroscope ?? this.hasHoroscope,
    hasMotivation: hasMotivation ?? this.hasMotivation,
    hasWeather: hasWeather ?? this.hasWeather,
    virtualCharacter: virtualCharacter ?? this.virtualCharacter,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
  );
}