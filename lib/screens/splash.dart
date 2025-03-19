import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:safebusiness/screens/Auth/location_access.dart';
import 'package:safebusiness/utils/color_resources.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key, LoginPage? nextScreen});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  void initState() {
    super.initState();
    checkNavigation(); // Check SharedPreferences to determine navigation
  }

  // Check SharedPreferences to see if user has already completed required pages
  Future<void> checkNavigation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool hasCompletedLocation = prefs.getBool('completedLocation') ?? false;
    bool hasCompletedScanQR = prefs.getBool('completedScanQR') ?? false;
    bool hasCompletedQRCodeScanner = prefs.getBool('completedQRCodeScanner') ?? false;
    bool hasCompletedRegister = prefs.getBool('completedRegister') ?? false;
    bool hasCompletedOTP = prefs.getBool('completedOTP') ?? false;

    bool isOnboardingComplete = hasCompletedLocation &&
        hasCompletedScanQR &&
        hasCompletedQRCodeScanner &&
        hasCompletedRegister &&
        hasCompletedOTP;

    // Delay for splash screen display
    await Future.delayed(const Duration(seconds: 4));

    // Navigate based on completion status
    if (isOnboardingComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          decoration: const BoxDecoration(color: mainColor),
          child: Center(
            child: Container(
              height: 138.0,
              width: 138.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/icons/logo.png'),
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
