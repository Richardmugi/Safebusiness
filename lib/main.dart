import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:provider/provider.dart';
import 'package:safebusiness/providers/dark_theme_provider.dart';
import 'package:safebusiness/screens/notify.dart';
import 'package:safebusiness/screens/splash.dart';
import 'package:safebusiness/utils/dark_theme_styles.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'helpers/route_helper.dart';
import 'package:device_preview/device_preview.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  //final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();

  // Step 3: Set local location for tz
  //tz.setLocalLocation(tz.getLocation(timeZoneName));
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
              home: Stack(
        children: [
          const MySplashScreen(
                nextScreen: null,
              ),  // Main visible screen
          Offstage(
            offstage: true, // Hides UI but keeps widget alive
            child: const NotificationsPage(), // Background logic widget
          ),
        ],
      ),
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
