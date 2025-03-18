import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safebusiness/providers/dark_theme_provider.dart';
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/splash.dart';
import 'package:safebusiness/utils/dark_theme_styles.dart';
import 'helpers/route_helper.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  bool _isFirstTimeUser = true; // Default to true
  Timer? _logoutTimer;
  static const Duration timeoutDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RouteHelper.setupRouter();
    checkIfFirstTimeUser();
    getCurrentAppTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoutTimer?.cancel();
    super.dispose();
  }

  // Monitor app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _startLogoutTimer();
    } else if (state == AppLifecycleState.resumed) {
      _cancelLogoutTimer();
    }
  }

  void _startLogoutTimer() {
    _logoutTimer = Timer(timeoutDuration, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        prefs.setBool('isLoggedIn', false); // Log out user
        if (GlobalContextService.navigatorKey.currentContext != null) {
          Navigator.of(GlobalContextService.navigatorKey.currentContext!)
              .pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
        }
      }
    });
  }

  void _cancelLogoutTimer() {
    _logoutTimer?.cancel();
  }

  Future<void> checkIfFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('completedOnboarding');

    setState(() {
      _isFirstTimeUser = isFirstTime ?? true;
    });
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => themeChangeProvider),
      ],
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return MaterialApp(
            title: 'Safebusiness',
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(themeChangeProvider.darkTheme, context),
            home: MySplashScreen(nextScreen: _isFirstTimeUser ? null : LoginPage()),
            onGenerateRoute: RouteHelper.router.generator,
            navigatorKey: GlobalContextService.navigatorKey, // Global key for navigation
          );
        },
      ),
    );
  }
}

class GlobalContextService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
