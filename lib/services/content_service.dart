import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/models/wakeup_content.dart';

class WeatherData {
  final String description;
  final double temperature;
  final String location;
  final String icon;

  WeatherData({
    required this.description,
    required this.temperature,
    required this.location,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      description: json['weather'][0]['description'] ?? 'Unknown',
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      location: json['name'] ?? 'Unknown',
      icon: json['weather'][0]['icon'] ?? '01d',
    );
  }

  String get temperatureCelsius => '${(temperature - 273.15).round()}°C';
  String get temperatureFahrenheit => '${((temperature - 273.15) * 9/5 + 32).round()}°F';
}

class ContentService {
  static const String _weatherApiKey = 'your_openweather_api_key'; // Replace with actual API key
  static const String _weatherBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static WakeupContent getContent(String language) {
    return language == 'es' ? ContentData.spanishContent : ContentData.englishContent;
  }

  static String getPersonalizedGreeting(UserProfile profile) {
    final content = getContent(profile.language);
    return content.getMorningGreeting(profile.name);
  }

  static String getMotivationalPhrase(String language) {
    final content = getContent(language);
    return content.getMotivationalPhrase();
  }

  static String getHoroscope(UserProfile profile) {
    final content = getContent(profile.language);
    return content.getHoroscope(profile.zodiacSign);
  }

  static Future<WeatherData?> getWeatherData({
    double? latitude,
    double? longitude,
    String? cityName,
  }) async {
    try {
      String url;
      if (latitude != null && longitude != null) {
        url = '$_weatherBaseUrl?lat=$latitude&lon=$longitude&appid=$_weatherApiKey';
      } else if (cityName != null) {
        url = '$_weatherBaseUrl?q=$cityName&appid=$_weatherApiKey';
      } else {
        // Default to a sample city if no location provided
        return _getSampleWeatherData();
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
    
    // Return sample weather data if API fails
    return _getSampleWeatherData();
  }

  static WeatherData _getSampleWeatherData() {
    final descriptions = [
      'Sunny and bright',
      'Partly cloudy',
      'Light rain',
      'Clear skies',
      'Overcast',
      'Warm and pleasant',
      'Cool and crisp',
      'Perfect weather',
    ];
    
    final now = DateTime.now();
    final descriptionIndex = now.day % descriptions.length;
    final temperature = 15 + (now.day % 20); // Temperature between 15-35°C
    
    return WeatherData(
      description: descriptions[descriptionIndex],
      temperature: temperature + 273.15, // Convert to Kelvin
      location: 'Your City',
      icon: '01d',
    );
  }

  static String formatWeatherMessage(WeatherData weather, String language) {
    if (language == 'es') {
      return 'El clima hoy en ${weather.location}: ${weather.description}, ${weather.temperatureCelsius}';
    } else {
      return 'Today\'s weather in ${weather.location}: ${weather.description}, ${weather.temperatureCelsius}';
    }
  }

  static String getRandomEncouragingWord(String language) {
    final encouragingWords = language == 'es' 
        ? [
            '¡Increíble!',
            '¡Fantástico!',
            '¡Maravilloso!',
            '¡Excelente!',
            '¡Brillante!',
            '¡Perfecto!',
            '¡Genial!',
            '¡Espectacular!',
          ]
        : [
            'Amazing!',
            'Fantastic!',
            'Wonderful!',
            'Excellent!',
            'Brilliant!',
            'Perfect!',
            'Awesome!',
            'Spectacular!',
          ];
    
    final now = DateTime.now();
    return encouragingWords[now.millisecond % encouragingWords.length];
  }

  static List<String> getWakeupContentList({
    required UserProfile profile,
    required bool includeHoroscope,
    required bool includeMotivation,
    required bool includeWeather,
    WeatherData? weatherData,
  }) {
    final contentList = <String>[];
    
    // Always start with personal greeting
    contentList.add(getPersonalizedGreeting(profile));
    
    // Add selected content types
    if (includeMotivation) {
      contentList.add(getMotivationalPhrase(profile.language));
    }
    
    if (includeHoroscope) {
      final horoscopeIntro = profile.language == 'es' 
          ? 'Tu horóscopo para hoy:'
          : 'Your horoscope for today:';
      contentList.add('$horoscopeIntro ${getHoroscope(profile)}');
    }
    
    if (includeWeather && weatherData != null) {
      contentList.add(formatWeatherMessage(weatherData, profile.language));
    }
    
    // Add encouraging closing
    final closing = profile.language == 'es'
        ? '¡Que tengas un día increíble!'
        : 'Have an amazing day!';
    contentList.add(closing);
    
    return contentList;
  }
}