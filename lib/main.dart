import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebusiness/providers/dark_theme_provider.dart';
import 'package:safebusiness/screens/splash.dart';
import 'package:safebusiness/utils/dark_theme_styles.dart';
import 'helpers/route_helper.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the updater
  final updater = ShorebirdUpdater();

  // 1️⃣ Check if there’s a new patch
  final status = await updater.checkForUpdate();

  if (status == UpdateStatus.outdated) {
    try {
      // 2️⃣ Download the patch
      await updater.update();
      // 3️⃣ Restart the app to apply it
      //await updater.installUpdateAndRestart();
      return; // the app is restarting
    } on UpdateException catch (err) {
      debugPrint('Failed to apply patch: $err');
    }
  }

  runApp(const MyApp());
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
