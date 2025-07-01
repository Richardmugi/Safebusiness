import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebusiness/providers/dark_theme_provider.dart';
import 'package:safebusiness/screens/message.dart';
import 'package:safebusiness/screens/splash.dart';
import 'package:safebusiness/utils/dark_theme_styles.dart';
import 'helpers/route_helper.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
//import 'package:workmanager/workmanager.dart';

/*const String checkInTask = "checkLateCheckIn";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == checkInTask) {
      await LateCheckInNotifier.checkAndSendLateSms();
    }
    return Future.value(true);
  });
}*/


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  /*await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Schedule once daily after 10:40 AM
  await Workmanager().registerPeriodicTask(
    "checkInTaskId",
    checkInTask,
    frequency: Duration(hours: 24),
    initialDelay: _calculateInitialDelay(),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );*/

  runApp(const MyApp());

  /*runApp(
    DevicePreview(
      //enabled: !kReleaseMode, // Only enable in debug/dev
      builder: (context) => const MyApp(),
    ),
  );*/
}

// Utility: Schedule the task to start at 10:40AM today (or tomorrow if passed)
/*Duration _calculateInitialDelay() {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month, now.day, 10, 0);
  if (now.isAfter(target)) {
    final tomorrow = target.add(Duration(days: 1));
    return tomorrow.difference(now);
  }
  return target.difference(now);
}*/



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  Timer? _sessionTimer;
  static const Duration sessionTimeout = Duration(minutes: 5);


    @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RouteHelper.setupRouter();
    _resetSessionTimer();
    saveAndScheduleNotification();
    _requestIOSPermissions();
  }


  Future<void> saveAndScheduleNotification() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String message = "Good morning. Don't forget to checkin.";
  TimeOfDay notificationTime = TimeOfDay(hour: 12, minute: 25);

  await prefs.setString('notification_message', message);
  await prefs.setInt('notification_hour', notificationTime.hour);
  await prefs.setInt('notification_minute', notificationTime.minute);

  scheduleNotification();
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


Future<void> scheduleNotification() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? message = prefs.getString('notification_message') ?? "Default reminder";
  int hour = prefs.getInt('notification_hour') ?? 9;
  int minute = prefs.getInt('notification_minute') ?? 0;

  // Next 9am
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    "Reminder",
    message,
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true,
    presentBadge: true,
    presentSound: true, ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    super.dispose();
  }

  /// Reset the session timer when user interacts
  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _redirectToSplashScreen);
  }

  /// Redirect to Splash Screen when session times out
  void _redirectToSplashScreen() {
    if (GlobalContextService.navigatorKey.currentContext != null) {
      Navigator.of(
        GlobalContextService.navigatorKey.currentContext!,
      ).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MySplashScreen(nextScreen: null),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetSessionTimer, // Reset session on tap
      onPanDown: (_) => _resetSessionTimer(), // Reset session on touch/scroll
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => themeChangeProvider),
        ],
        child: Consumer<DarkThemeProvider>(
          builder: (context, value, child) {
            return MaterialApp(
              title: 'Safebusiness',
              //useInheritedMediaQuery: true,
              //locale: DevicePreview.locale(context),
              //builder: DevicePreview.appBuilder,
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(themeChangeProvider.darkTheme, context),
              home: MySplashScreen(
                nextScreen: null,
              ), // Always start from splash
              onGenerateRoute: RouteHelper.router.generator,
              navigatorKey: GlobalContextService.navigatorKey,
            );
          },
        ),
      ),
    );
  }
}

class GlobalContextService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
