import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safebusiness/screens/home.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String companyEmail = "";
  int branchId = 0;
  String branchName = "";

  @override
  void initState() {
    super.initState();
    _requestIOSPermissions();
    _initNotifications();
    _scheduleDailyCheckInReminder();
    //_scheduleLateCheckInReminder();
  }

  void _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}


  /*Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == 'late_checkin') {
          final isCheckedIn = await CheckInManager.isCheckedIn();
          if (!isCheckedIn) {
            await flutterLocalNotificationsPlugin.show(
              3,
              "You're Late",
              "You haven’t checked in today. Please check in now.",
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'actual_late_alert',
                  'Late Alert',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentSound: true,
                ),
              ),
            );
          }
        }
      },
    );
  }*/

  Future<void> _scheduleDailyCheckInReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      0,
    );

    final reminderTime =
        scheduledTime.isBefore(now)
            ? scheduledTime.add(Duration(days: 1))
            : scheduledTime;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1, // Notification ID
      'Check-In Reminder',
      'Please remember to check in',
      reminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true, // 🔔 This is the key for iOS sound
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /*Future<void> _scheduleLateCheckInReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final checkTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );

    final scheduledTime =
        checkTime.isBefore(now)
            ? checkTime.add(const Duration(days: 1))
            : checkTime;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      2, // Unique ID for late check-in notification
      'Late Check-In Check',
      'Checking if you checked in...',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'late_checkin_channel',
          'Late Check-In',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: "late_checkin", // used for identifying the type
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications Page")),
      body: const Center(
        child: Text("Local notifications handler is running..."),
      ),
    );
  }
}
