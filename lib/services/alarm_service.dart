import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static AlarmSettings alarmSettings = AlarmSettings(
    id: 0,
    dateTime: tz.TZDateTime.now(tz.local),
    assetAudioPath: 'assets/alarm.m4a',
    volumeSettings: VolumeSettings.fade(
        fadeDuration: Duration(seconds: 10),
        volumeEnforced: false,
        volume: 0.8),
    notificationSettings: NotificationSettings(
        title: 'Wake up!',
        body: 'Time to start your amazing day!',
        stopButton: 'Stop',
        icon: '@mipmap/ic_launcher',
        iconColor: Colors.red),
    loopAudio: true,
  );

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    await _requestPermissions();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    Alarm.ringStream.stream.listen((alarmSettings) async {
      try {
        final alarms = await StorageService.getAlarms();
        Alarms? alarm;
        try {
          alarm = alarms.firstWhere((a) => a.id.hashCode == alarmSettings.id);
        } catch (e) {
          // not found
          alarm = null;
        }

        if (alarm != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) =>
                  WakeupScreen(alarm: alarm!, id: alarmSettings.id),
            ),
          );
        } else {
          debugPrint('Wakeup: alarm not found for id=${alarmSettings.id}');
        }
      } catch (e) {
        debugPrint('Error handling ringStream: $e');
      }
    });

    // await _notifications.initialize(
    //   initSettings,
    //   onDidReceiveNotificationResponse: _onNotificationResponse,
    // );

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();

    // Request additional Android 13+ permissions
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // static void _onNotificationResponse(NotificationResponse response) async {
  //   // Try to get the alarm id from the payload

  //   print("Notification Response: ${response.payload}");

  //   final alarmId = response.payload;
  //   if (alarmId == null) return;
  //   final alarms = await StorageService.getAlarms();
  //   Alarms? alarm;
  //   try {
  //     alarm = alarms.firstWhere((a) => a.id == alarmId);
  //   } catch (_) {
  //     return;
  //   }
  //   navigatorKey.currentState?.push(
  //     MaterialPageRoute(
  //       builder: (context) => WakeupScreen(alarm: alarm!),
  //     ),
  //   );
  // }

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

    await _scheduleNotification(alarm, scheduledDate);

    // Schedule recurring alarms for the next week
    if (alarm.isRepeating) {
      await _scheduleRepeatingAlarms(alarm, scheduledDate);
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

    // const androidDetails = AndroidNotificationDetails(
    //   'alarm_channel',
    //   'Alarms',
    //   channelDescription: 'Dawn Weaver alarm notifications',
    //   importance: Importance.max,
    //   priority: Priority.high,
    //   fullScreenIntent: true,
    //   category: AndroidNotificationCategory.alarm,
    // );

    // const iosDetails = DarwinNotificationDetails(
    //   presentAlert: true,
    //   presentBadge: true,
    //   presentSound: true,
    //   categoryIdentifier: 'alarm_category',
    // );

    // const details = NotificationDetails(
    //   android: androidDetails,
    //   iOS: iosDetails,
    // );

    final title = alarm.label.isNotEmpty ? alarm.label : 'Wake up!';
    final body = 'Time to start your amazing day!';

    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    alarmSettings = AlarmSettings(
      id: notificationId ?? id,
      dateTime: tzScheduledDate,
      assetAudioPath: 'assets/alarm.m4a',
      volumeSettings: VolumeSettings.fade(
          fadeDuration: Duration(seconds: 10),
          volumeEnforced: false,
          volume: 0.8),
      notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: 'Stop',
          icon: '@mipmap/ic_launcher',
          iconColor: Colors.red),
      loopAudio: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);

    prefs.setInt('alarmActive', id);

    // await _notifications.zonedSchedule(
    //   id,
    //   title,
    //   body,
    //   scheduledDate3,
    //   details,
    //   androidScheduleMode: AndroidScheduleMode.alarmClock,
    //   payload: alarm.id,
    // );
  }

  static Future<void> cancelAlarm(String alarmId) async {
    // Cancel all possible notifications for this alarm (including repeating ones)
    await Alarm.stop(alarmId.hashCode);
  }

  static Future<void> snoozeAlarm(String alarmId, int minutes) async {
    final alarms = await StorageService.getAlarms();
    final alarm = alarms.firstWhere((a) => a.id == alarmId);

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozeAlarm = alarm.copyWith(
      time: snoozeTime,
      id: '${alarm.id}_snooze_${DateTime.now().millisecondsSinceEpoch}',
    );

    await scheduleAlarm(snoozeAlarm);
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
