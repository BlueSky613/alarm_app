import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dawn_weaver/theme.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/screens/user_setup_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/language_service.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/l10n/app_localizations_delegate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final LanguageService languageService = LanguageService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getString('config') == null) {
    final url = Uri.parse(
        '${dotenv.env['base_url']}/api/v1/config'); // Replace with your URL
    final response = await http.get(url);
    if (response.statusCode == 200) {
      await prefs.setString('config', response.body);
    }
  }

  final alarms = await StorageService.getAlarms();

  // Check if user setup is complete
  final bool isSetupComplete = prefs.getBool('setup_complete') ?? false;

  final int? activeAlarmId = prefs.getInt('alarmActive');
  if (activeAlarmId != null && activeAlarmId != 0) {
    final alarm = alarms.firstWhere((a) => a.id.hashCode == activeAlarmId);
    bool result = await Alarm.isRinging(activeAlarmId);
    if (result) {
      runApp(ActiveAlarmApp(alarm: alarm, id: activeAlarmId));
      return;
    }
  }

  runApp(DawnWeaverApp(showSetup: !isSetupComplete));
}

class DawnWeaverApp extends StatelessWidget {
  final bool showSetup;

  const DawnWeaverApp({super.key, this.showSetup = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageService,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Dawn Weaver',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'), // Spanish
            Locale('en'), // English
          ],
          home: showSetup ? const UserSetupScreen() : const HomePage(),
        );
      },
    );
  }
}

class ActiveAlarmApp extends StatelessWidget {
  final Alarms alarm;
  final int id;

  const ActiveAlarmApp({super.key, required this.alarm, required this.id});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageService,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Dawn Weaver',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'), // Spanish
            Locale('en'), // English
          ],
          home: WakeupScreen(alarm: alarm, id: id),
        );
      },
    );
  }
}
