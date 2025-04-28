import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebusiness/providers/dark_theme_provider.dart';
import 'package:safebusiness/screens/splash.dart';
import 'package:safebusiness/utils/dark_theme_styles.dart';
import 'helpers/route_helper.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      //enabled: !kReleaseMode,           // Turn off in release builds if you like
      builder: (context) => MyApp(),    // Wrap your app
    ),
  );
}

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
      Navigator.of(GlobalContextService.navigatorKey.currentContext!)
          .pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MySplashScreen(nextScreen: null)),
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
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(themeChangeProvider.darkTheme, context),
              home: MySplashScreen(nextScreen: null), // Always start from splash
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
