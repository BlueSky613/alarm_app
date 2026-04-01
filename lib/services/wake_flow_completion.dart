import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';

/// After the user finishes the alignment step (confirm or device back).
/// Quick Alarm / Power Nap: remove alarm; one-shot: deactivate; clear active flag.
Future<void> applyWakeExitSideEffects(
  Alarms alarm, {
  required bool isPreview,
}) async {
  final prefs = await SharedPreferences.getInstance();

  if (!isPreview &&
      (alarm.label == 'Quick Alarm' || alarm.label == 'Power Nap')) {
    await StorageService.deleteAlarm(alarm.id);
    await AlarmService.cancelAlarm(alarm.id);
  } else if (!isPreview && alarm.repeatDays.isEmpty) {
    await StorageService.saveAlarm(alarm.copyWith(isActive: false));
    await AlarmService.cancelAlarm(alarm.id);
  }

  if (!isPreview) {
    prefs.setInt('alarmActive', 0);
  }
}
