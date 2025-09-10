import 'package:flutter/material.dart';
import 'package:dawn_weaver/theme.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  final alarms = await StorageService.getAlarms();

  // Listen to alarm events globally
  final int? activeAlarmId = prefs.getInt('alarmActive');
  print("Active Alarm ID: $activeAlarmId");
  if (activeAlarmId != null && activeAlarmId != 0) {
    final alarm = alarms.firstWhere((a) => a.id.hashCode == activeAlarmId);
    bool result = await Alarm.isRinging(activeAlarmId);
    if (result) {
      runApp(ActiveAlarmApp(alarm: alarm, id: activeAlarmId));
    } else {
      runApp(const DawnWeaverApp());
    }
  } else {
    runApp(const DawnWeaverApp());
  }
}

class DawnWeaverApp extends StatelessWidget {
  const DawnWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dawn Weaver',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class ActiveAlarmApp extends StatelessWidget {
  final Alarms alarm;
  final int id;

  const ActiveAlarmApp({super.key, required this.alarm, required this.id});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dawn Weaver',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: WakeupScreen(alarm: alarm, id: id),
    );
  }
}
