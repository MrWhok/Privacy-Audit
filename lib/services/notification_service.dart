import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showSaveSuccess(String appName, String riskLevel) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'save_channel',
        'Save Notifications',
        channelDescription: 'Shown when an app entry is saved',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        2,
        'Entry saved',
        '$appName added to your audit ($riskLevel risk)',
        details,
      );
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> showCriticalAlert(String appName) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'critical_channel',
        'Critical Risk Alerts',
        channelDescription: 'Alerts when a Critical risk app is added',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        0,
        'Critical risk detected',
        '$appName has sensitive permissions. Review it now.',
        details,
      );
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> showUpdateSuccess(String appName) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'save_channel',
        'Save Notifications',
        channelDescription: 'Shown when an app entry is saved',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        3,
        'Entry updated',
        '$appName has been updated in your audit.',
        details,
      );
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> showDeleteSuccess(String appName) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'save_channel',
        'Save Notifications',
        channelDescription: 'Shown when an app entry is saved',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        4,
        '🗑️ Entry deleted',
        '$appName removed from your audit.',
        details,
      );
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> scheduleMonthlyReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Monthly Reminders',
        channelDescription: 'Monthly permission audit reminders',
        importance: Importance.defaultImportance,
      );
      const details = NotificationDetails(android: androidDetails);
      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(days: 30));
      await _plugin.zonedSchedule(
        1,
        'Time to re-audit',
        'Review your app permissions to stay safe.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
