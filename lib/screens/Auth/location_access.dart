import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safebusiness/screens/Auth/scan_qr_code.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/utils/dimensions.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationAccess extends StatefulWidget {
  const LocationAccess({super.key});

  @override
  _LocationAccessState createState() => _LocationAccessState();
}

class _LocationAccessState extends State<LocationAccess> {
  Future<void> saveLocationCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completedLocation', true);
  }

  /// **Function to check and request location permission**
  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission denied. Please allow access."),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Location permissions are permanently denied. Enable them in settings."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  /// **Function to get the device's current location**
  Future<void> _getCurrentLocation() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Print location for debugging
      print("Current Location: Lat: ${position.latitude}, Lng: ${position.longitude}");

      // Save location to SharedPreferences (Optional)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);

      // Navigate after fetching location
      await saveLocationCompletion();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ScanQRCode(),
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              verticalSpacing(MediaQuery.of(context).size.height * 0.1),
              const Text(
                'Location Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: black,
                ),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.03),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 165,
                    width: 165,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 167, 162, 162),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/placeholder.png',
                        color: mainColor,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.09),
              const Text(
                "Enable Premise Location",
                style: TextStyle(
                  fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                ),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.04),
              const Text(
                "Enable on-premise location to help the app provide personalised information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Dimensions.FONT_SIZE_DEFAULT,
                  fontWeight: FontWeight.w400,
                  color: darkgrey,
                ),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.18),
              ActionButton(
                onPressed: _getCurrentLocation, // Fetch location when button is pressed
                actionText: "Turn on Location",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
