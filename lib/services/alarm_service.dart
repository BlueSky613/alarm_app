import 'dart:io';

import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/utils/virtual_character_video.dart';
import 'package:dawn_weaver/main.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/utils/constants.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool _isDeviceFilePath(String soundPath) {
    final lower = soundPath.toLowerCase();
    return lower.startsWith('/') ||
        lower.startsWith('file://') ||
        lower.contains(':\\');
  }

  /// Downloads a remote alarm track into app Documents and returns a path
  /// relative to Documents (required by the `alarm` package). Falls back to
  /// [assets/alarm.m4a] only if the download fails.
  static Future<String> _cacheHttpAudioToDocuments(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = '${url.hashCode.abs()}.mp3';
    final rel = p.join('alarm_cache', safeName);
    final file = File(p.join(dir.path, rel));
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          await file.writeAsBytes(resp.bodyBytes);
        } else {
          return 'assets/alarm.m4a';
        }
      } catch (_) {
        return 'assets/alarm.m4a';
      }
    }
    return rel;
  }

  /// The `alarm` package only accepts bundled assets or paths relative to app
  /// Documents. Resolves HTTPS presets, local picker paths, or falls back.
  static Future<String> resolveAssetAudioPath(String soundPath) async {
    final trimmed = soundPath.trim();
    if (trimmed.isEmpty ||
        trimmed == 'default' ||
        (!_isDeviceFilePath(trimmed) &&
            !trimmed.startsWith('http://') &&
            !trimmed.startsWith('https://') &&
            !trimmed.startsWith('assets/'))) {
      return _cacheHttpAudioToDocuments(AppConstants.defaultAlarmSoundUrl);
    }
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _cacheHttpAudioToDocuments(trimmed);
    }

    final dir = await getApplicationDocumentsDirectory();

    var srcPath = trimmed;
    if (srcPath.toLowerCase().startsWith('file://')) {
      srcPath = Uri.parse(srcPath).toFilePath();
    }
    final src = File(srcPath);
    if (!await src.exists()) {
      return 'assets/alarm.m4a';
    }
    final base = p.basename(src.path);
    final rel = p.join('alarm_custom', base);
    final dest = File(p.join(dir.path, rel));
    await dest.parent.create(recursive: true);
    await src.copy(dest.path);
    return rel;
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    await _requestPermissions();

    Alarm.ringStream.stream.listen((alarmSettings) async {
      try {
        final alarms = await StorageService.getAlarms();
        Alarms? alarm;
        final payload = alarmSettings.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            alarm = alarms.firstWhere((a) => a.id == payload);
          } catch (_) {}
        }
        alarm ??= () {
          try {
            return alarms.firstWhere(
                (a) => a.id.hashCode == alarmSettings.id);
          } catch (_) {
            return null;
          }
        }();

        if (alarm != null) {
          VideoPlayerController? preloaded;
          if (alarm.virtualCharacter != 'default') {
            preloaded = await preloadVirtualCharacterVideo(
              alarm.virtualCharacter,
              mute: alarm.muteVirtualCharacterAudio,
            );
          }
          if (navigatorKey.currentState?.mounted != true) return;
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => WakeupScreen(
                alarm: alarm!,
                id: alarmSettings.id,
                preloadedVideoController: preloaded,
              ),
            ),
          );
        } else {
          debugPrint('Wakeup: alarm not found for id=${alarmSettings.id}');
        }
      } catch (e) {
        debugPrint('Error handling ringStream: $e');
      }
    });

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();

    // Request additional Android 13+ permissions
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> scheduleAlarm(Alarms alarm) async {
    await initialize();

    print(
        "Scheduling alarm: ${alarm.id} at ${alarm.time}, active: ${alarm.isActive}");

    if (!alarm.isActive) return;

    // Cancel existing notifications for this alarm
    await cancelAlarm(alarm.id);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If the time has passed today, schedule for tomorrow or next occurrence
    if (scheduledDate.isBefore(now)) {
      if (alarm.isRepeating) {
        scheduledDate = _getNextRepeatingDate(scheduledDate, alarm.repeatDays);
      } else {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    if (alarm.isRepeating) {
      await _scheduleRepeatingAlarms(alarm, scheduledDate);
    } else {
      await _scheduleNotification(alarm, scheduledDate);
    }
  }

  static DateTime _getNextRepeatingDate(
      DateTime baseDate, Set<int> repeatDays) {
    var date = baseDate;
    while (!repeatDays.contains(date.weekday % 7)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  static Future<void> _scheduleRepeatingAlarms(
      Alarms alarm, DateTime firstDate) async {
    final scheduledDates = <DateTime>[];
    var currentDate = firstDate;

    // Schedule for the next 30 days to handle repeating alarms
    for (int i = 0; i < 30; i++) {
      if (alarm.repeatDays.contains(currentDate.weekday % 7)) {
        scheduledDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (int i = 0; i < scheduledDates.length; i++) {
      await _scheduleNotification(
        alarm,
        scheduledDates[i],
        notificationId: alarm.id.hashCode + i,
      );
    }
  }

  static Future<void> _scheduleNotification(
    Alarms alarm,
    DateTime scheduledDate, {
    int? notificationId,
  }) async {
    final id = alarm.id.hashCode;
    final prefs = await SharedPreferences.getInstance();

    final label = alarm.label.trim();
    final title = label.isNotEmpty ? label : 'Wake up!';
    final body = 'Time to start your amazing day!';

    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    final assetAudioPath = await resolveAssetAudioPath(alarm.soundPath);

    final profile = await StorageService.getUserProfile();
    final soundEnabled = profile?.soundNotificationsEnabled ?? true;
    final hapticEnabled = profile?.hapticEnabled ?? true;

    final settings = AlarmSettings(
      id: notificationId ?? id,
      dateTime: tzScheduledDate,
      assetAudioPath: assetAudioPath,
      volumeSettings: soundEnabled
          ? VolumeSettings.fade(
              fadeDuration: Duration(seconds: 10),
              volumeEnforced: false,
              volume: 0.8)
          : VolumeSettings.fixed(volume: 0.0),
      notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: 'Stop',
          icon: '@mipmap/ic_launcher',
          iconColor: Colors.red),
      vibrate: hapticEnabled,
      loopAudio: true,
      payload: alarm.id,
    );

    await Alarm.set(alarmSettings: settings);

    prefs.setInt('alarmActive', notificationId ?? id);
  }

  static Future<void> cancelAlarm(String alarmId) async {
    final saved = await Alarm.getAlarms();
    for (final a in saved) {
      if (a.payload == alarmId) {
        await Alarm.stop(a.id);
      }
    }
    await Alarm.stop(alarmId.hashCode);
    for (var i = 0; i < 30; i++) {
      await Alarm.stop(alarmId.hashCode + i);
    }
  }

  static Future<void> snoozeAlarm(String alarmId, int minutes) async {
    final alarms = await StorageService.getAlarms();
    final alarm = alarms.firstWhere((a) => a.id == alarmId);

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final updated = alarm.copyWith(time: snoozeTime);

    await StorageService.saveAlarm(updated);
    await scheduleAlarm(updated);
  }

  static Future<void> rescheduleAllAlarms() async {
    final alarms = await StorageService.getAlarms();
    for (final alarm in alarms.where((a) => a.isActive)) {
      await scheduleAlarm(alarm);
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }
}
