import 'dart:async';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static StreamController<NotificationResponse> streamController =
      StreamController();
  static onTap(NotificationResponse notificationResponse) {
    // log(notificationResponse.id!.toString());
    // log(notificationResponse.payload!.toString());
    streamController.add(notificationResponse);
    // Navigator.push(context, route);
  }

  static Future init() async {
    InitializationSettings settings = const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );
  }

  //showSchduledNotification
  //showSchduledNotification
  static void showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'scheduled_notification',
      'Discussion Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    NotificationDetails details = const NotificationDetails(
      android: android,
    );

    // Initialize time zones
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      log("Set Time Zone: $currentTimeZone");
    } catch (e) {
      log('Failed to detect time zone. Setting to UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    // final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    // log("Detected Time Zone from FlutterTimezone: $currentTimeZone");
    // tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    // log("Fallback to default time zone: Asia/Riyavdh");

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: 'ClubDiscussion-$id',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }
//   static Future<void> enableNotifications() async {
//     // Initialize notifications or reschedule previously canceled ones
//     log('Notifications enabled via LocalNotificationService.');
//   }

//   static Future<void> disableNotifications() async {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   await flutterLocalNotificationsPlugin.cancelAll();
//   log('All notifications have been canceled.');
// }
}
