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
import 'package:video_player/video_player.dart';
import 'package:dawn_weaver/utils/virtual_character_video.dart';
import 'package:dawn_weaver/app_route_observer.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final LanguageService languageService = LanguageService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();

  final alarms = await StorageService.getAlarms();

  // App session is now driven by backend-issued token existence.
  final bool hasAuthToken = await StorageService.hasAuthToken();
  if (!hasAuthToken) {
    runApp(const DawnWeaverApp(showSetup: true));
    return;
  }

  final int? activeAlarmId = prefs.getInt('alarmActive');
  if (activeAlarmId != null && activeAlarmId != 0) {
    final settings = await Alarm.getAlarm(activeAlarmId);
    Alarms? alarm;
    final payload = settings?.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        alarm = alarms.firstWhere((a) => a.id == payload);
      } catch (_) {}
    }
    alarm ??= () {
      try {
        return alarms.firstWhere((a) => a.id.hashCode == activeAlarmId);
      } catch (_) {
        return null;
      }
    }();
    if (alarm != null) {
      final bool ringing = await Alarm.isRinging(activeAlarmId);
      if (ringing) {
        VideoPlayerController? preloaded;
        if (alarm.virtualCharacter != 'default') {
          preloaded = await preloadVirtualCharacterVideo(
            alarm.virtualCharacter,
            mute: alarm.muteVirtualCharacterAudio,
          );
        }
        runApp(
          ActiveAlarmApp(
            alarm: alarm,
            id: activeAlarmId,
            preloadedVideoController: preloaded,
          ),
        );
        return;
      }
    }
  }

  runApp(DawnWeaverApp(showSetup: !hasAuthToken));
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
          navigatorObservers: [appRouteObserver],
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
  final VideoPlayerController? preloadedVideoController;

  const ActiveAlarmApp({
    super.key,
    required this.alarm,
    required this.id,
    this.preloadedVideoController,
  });

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
          home: WakeupScreen(
            alarm: alarm,
            id: id,
            preloadedVideoController: preloadedVideoController,
          ),
        );
      },
    );
  }
}
