import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

   static Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      print('Notification Permission Granted: $granted'); // Debugging
    }
  }
}

  /// 🌍 Set local timezone based on user location
  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    print('🕒 Local Timezone Set: $timeZoneName');
  }

  static Future<void> init() async {
    await _configureLocalTimeZone(); // ✅ Ensure the timezone is set

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Notification Clicked: ${response.payload}");
      },
    );

    // ✅ Request permissions for Android 13+
    await requestPermissions();

    // ✅ Create notification channel (important for Android 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_id',
      'Scheduled Notifications',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleNotifications() async {
    await _scheduleNotification(1, "Check-in Reminder", "Remember to check in!", 8, 0);
    await _scheduleNotification(2, "Check-out Reminder", "Remember to check out!", 17, 0);
  }

  /// ✅ Ensure notifications use the user's local time
  static Future<void> _scheduleNotification(int id, String title, String body, int hour, int minute) async {
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);

    print('📅 Scheduling Notification: $title at $scheduledTime (Local)');

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime, // 🌍 Now in local time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Scheduled Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 📌 Get the next local time instance for notification
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('🔔 Final Scheduled Notification Time (Local): $scheduledDate');
    return scheduledDate;
  }
}
