import 'dart:convert';
import 'package:dawn_weaver/services/location_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/models/wakeup_content.dart';
import 'package:dawn_weaver/services/storage_service.dart';

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
  String get temperatureFahrenheit =>
      '${((temperature - 273.15) * 9 / 5 + 32).round()}°F';
}

class ContentService {
  static String _weatherApiKey = dotenv.env['weather_api_key'] ?? '';
  static const String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _horoscopeBaseUrl =
      'https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily';

  static WakeupContent getContent(String language) {
    return language == 'es'
        ? ContentData.spanishContent
        : ContentData.englishContent;
  }

  static String getPersonalizedGreeting(UserProfile profile) {
    final content = getContent(profile.language);
    return content.getMorningGreeting(profile.name);
  }

  static String getMotivationalPhrase(String language) {
    final content = getContent(language);
    return content.getMotivationalPhrase();
  }

  static getHoroscopeWeather(UserProfile profile) async {
    final location = await LocationService.getCurrentPosition();
    try {
      String url1, url2;
      String horoscope = "", weather = "";
      url1 =
          '$_horoscopeBaseUrl?sign=${profile.zodiacSign.toString().split('.')[1]}&day=TODAY';
      final response = await http.get(Uri.parse(url1));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        horoscope = data['data']['horoscope_data'];
      }
      if (location != null) {
        url2 =
            '$_weatherBaseUrl?lat=${location.latitude}&lon=${location.longitude}&appid=$_weatherApiKey';
        final response = await http.get(Uri.parse(url2));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          weather = formatWeatherMessage(
              WeatherData.fromJson(data), profile.language);
        }
      }
      final profiles = profile.copyWith(
        weather: weather,
        horoscope: horoscope,
      );
      await StorageService.saveUserProfile(profiles);
    } catch (e) {
      print('Error fetching horoscope: $e');
    }
  }

  // static Future<WeatherData?> getWeatherData(UserProfile profile) async {
  //   try {
  //     String url;
  //     final location = await LocationService.getCurrentPosition();
  //     if (location != null) {
  //       url =
  //           '$_weatherBaseUrl?lat=${location.latitude}&lon=${location.longitude}&appid=$_weatherApiKey';
  //       final response = await http.get(Uri.parse(url));
  //       if (response.statusCode == 200) {
  //         final data = json.decode(response.body);
  //         final profiles = UserProfile(
  //           weather: formatWeatherMessage(
  //               WeatherData.fromJson(data), profile.language),
  //         );
  //         await StorageService.saveUserProfile(profiles);
  //         return WeatherData.fromJson(data);
  //       }
  //     } else {
  //       // Default to a sample city if no location provided
  //       return _getSampleWeatherData();
  //     }
  //   } catch (e) {
  //     print('Error fetching weather data: $e');
  //   }

  //   // Return sample weather data if API fails
  //   return _getSampleWeatherData();
  // }

  // static WeatherData _getSampleWeatherData() {
  //   final descriptions = [
  //     'Sunny and bright',
  //     'Partly cloudy',
  //     'Light rain',
  //     'Clear skies',
  //     'Overcast',
  //     'Warm and pleasant',
  //     'Cool and crisp',
  //     'Perfect weather',
  //   ];

  //   final now = DateTime.now();
  //   final descriptionIndex = now.day % descriptions.length;
  //   final temperature = 15 + (now.day % 20); // Temperature between 15-35°C

  //   return WeatherData(
  //     description: descriptions[descriptionIndex],
  //     temperature: temperature + 273.15, // Convert to Kelvin
  //     location: 'Your City',
  //     icon: '01d',
  //   );
  // }

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
    String? weatherData,
    String? horoscope,
    String? motivationMessage,
  }) {
    final contentList = <String>[];

    // Always start with personal greeting
    contentList.add(getPersonalizedGreeting(profile));

    // Add selected content types
    if (includeMotivation && motivationMessage != null) {
      contentList.add(motivationMessage);
    }

    if (includeHoroscope) {
      final horoscopeIntro = profile.language == 'es'
          ? 'Tu horóscopo para hoy:'
          : 'Your horoscope for today:';
      contentList.add('$horoscopeIntro ${horoscope ?? ''}');
    }

    if (includeWeather && weatherData != null) {
      contentList.add(weatherData);
    }

    // Add encouraging closing
    final closing = profile.language == 'es'
        ? '¡Que tengas un día increíble!'
        : 'Have an amazing day!';
    contentList.add(closing);

    return contentList;
  }
}
