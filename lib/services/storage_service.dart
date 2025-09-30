import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';

class StorageService {
  static const String _alarmsKey = 'alarms';
  static const String _userProfileKey = 'user_profile';
  static const String _firstRunKey = 'first_run';

  static Future<List<Alarms>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList(_alarmsKey) ?? [];

    return alarmsJson.map((json) => Alarms.fromJson(jsonDecode(json))).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  static Future<void> saveAlarms(List<Alarms> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson =
        alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList(_alarmsKey, alarmsJson);
  }

  static Future<void> saveAlarm(Alarms alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);

    print("index: $index");
    print("alarm: ${alarm.toJson()}");
    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }

    await saveAlarms(alarms);
  }

  static Future<void> deleteAlarm(String alarmId) async {
    final alarms = await getAlarms();
    alarms.removeWhere((alarm) => alarm.id == alarmId);
    await saveAlarms(alarms);
  }

  static Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);

    if (profileJson == null) return null;

    return UserProfile.fromJson(jsonDecode(profileJson));
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunKey) ?? true;
  }

  static Future<void> setFirstRun(bool isFirstRun) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, isFirstRun);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
