import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String companyEmail = "";
  int branchId = 0;
  String branchName = "";
  late Timer _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _requestIOSPermissions();
    _loadUserDetails();
    _scheduleDailyCheckInReminder();
}

@override
void dispose() {
  _pollingTimer.cancel();
  super.dispose();
}


void _requestIOSPermissions() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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

   _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
    await _fetchJobs();
    await _fetchAnnouncements();
  });
}


  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'main_channel',
      'Main Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true, // 🔔 enable sound
  );
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iOSDetails,
  );
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  Future<void> _scheduleDailyCheckInReminder() async {
  final now = tz.TZDateTime.now(tz.local);
  final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 13, 18);

  final reminderTime = scheduledTime.isBefore(now)
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

Future<void> _fetchBranchName(int branchId) async {
    var url = Uri.parse(
      "http://65.21.59.117/safe-business-api/public/api/v1/getCompanyBranches",
    );
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"companyEmail": companyEmail}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS") {
        var branch = (data["branches"] as List).firstWhere(
          (b) => b["id"] == branchId,
          orElse: () => null,
        );
        setState(() {
          branchName = branch != null ? branch["name"] : "Unknown Branch";
        });
      }
    }
  }


  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    companyEmail = prefs.getString("companyEmail") ?? "";
    branchId = prefs.getInt("branchId") ?? 0;
    _fetchBranchName(branchId).then((_) {
    _fetchAnnouncements();
    _fetchJobs();
  });
  }

  Future<void> _fetchJobs() async {
    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyJobsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedJobs");

    var body = jsonEncode(branchId > 0
        ? {"companyEmail": companyEmail, "branchId": branchId}
        : {"companyEmail": companyEmail});

    try {
      var response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200) {
        print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS" && data["postedJobs"] is List) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int previousCount = prefs.getInt("jobCount") ?? 0;
          List jobs = data["postedJobs"];
          if (jobs.length > previousCount) {
            print("New Job Posted");
            await _showNotification("New Job Posted", "${jobs.length - previousCount} new job(s) available.");
            prefs.setInt("jobCount", jobs.length);
          }
        }
      }
    } catch (e) {
      print("Job fetch failed: $e");
    }
  }

  Future<void> _fetchAnnouncements() async {
    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyAnnouncementsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedAnnouncements");

    var body = jsonEncode(branchId > 0
        ? {"companyEmail": companyEmail, "branchId": branchId}
        : {"companyEmail": companyEmail});

    try {
      var response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200) {
        print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS" && data["announcements"] is List) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int previousCount = prefs.getInt("announcementCount") ?? 0;
          List announcements = data["announcements"];
          if (announcements.length > previousCount) {
            print("New Announcemnt Posted");
            await _showNotification("New Announcement", "${announcements.length - previousCount} new announcement(s).");
            prefs.setInt("announcementCount", announcements.length);
          }
        }
      }
    } catch (e) {
      print("Announcement fetch failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications Page")),
      body: const Center(child: Text("Local notifications handler is running...")),
    );
  }
}
