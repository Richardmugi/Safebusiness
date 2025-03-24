import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:safebusiness/screens/QRCodeScanner.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/carousel.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  String employeeId = "";
  String employeeName = "";
  String employeeEmail = "";
  String companyEmail = "";
  int selectedIndex = -1; // Initially, no box is selected

  bool isValidEmail(String input) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(input);
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeId = prefs.getString('employeeId') ?? "N/A";
      employeeName = prefs.getString('employeeName') ?? "N/A";
      employeeEmail = prefs.getString('email') ?? "N/A";
      companyEmail = prefs.getString('companyEmail') ?? "N/A";
    });
  }

  Future<void> _saveNotification(String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    String timestamp = DateFormat(
      'hh:mm a EEE MMM d, y',
    ).format(DateTime.now());
    notifications.insert(0, "$message - $timestamp");
    await prefs.setStringList('notifications', notifications);
  }

  Future<void> _clockin(String email, String companyEmail) async {
    if (!mounted) return;

    Position? userPosition = await _determinePosition();
    if (userPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to determine location"),
          backgroundColor: mainColor,
        ),
      );
      _saveNotification("Check-in failed: Unable to determine location");
      return;
    }

    double userLatitude = userPosition.latitude;
    double userLongitude = userPosition.longitude;

    var branchLocation = await _getBranchLocation(companyEmail);
    if (branchLocation == null ||
        branchLocation['latitude'] == null ||
        branchLocation['longitude'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Branch location not found"),
          backgroundColor: mainColor,
        ),
      );
      _saveNotification("Check-in failed: Branch location not found");
      return;
    }

    double? branchLatitude = branchLocation['latitude'];
    double? branchLongitude = branchLocation['longitude'];

    double distanceInMeters = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      branchLatitude!,
      branchLongitude!,
    );

    if (distanceInMeters > 500) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are too far from your branch to check in"),
          backgroundColor: mainColor,
        ),
      );
      _saveNotification("Check-in failed: Too far from branch");
      return;
    }

    var url = Uri.parse(
      'http://65.21.59.117/safe-business-api/public/api/v1/employeeClockIn',
    );

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "employeeEmail": email,
          "companyEmail": companyEmail,
          "latitude": userLatitude,
          "longitude": userLongitude,
        }),
      );

      var responseData = jsonDecode(response.body);
      print("Check-in Response: $responseData");

      String message = responseData["message"] ?? "Unknown error occurred";

      if (response.statusCode == 200 && responseData["status"] == "SUCCESS") {
        _saveNotification("Check-in successful");

        // Trigger vibration
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 500); // Vibrate for 500ms
        }

        // Play system notification sound
        _ringtonePlayer.playNotification();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Check-in success"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _saveNotification("Check-in failed: $message");

        // Trigger vibration for failure
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 200); // Short vibration for failure
        }

        // Play system alarm sound for failure
        _ringtonePlayer.play(
          fromAsset: "system/alarm", // Use system alarm sound
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Check-in failed: $message"),
            backgroundColor: mainColor,
          ),
        );
      }
    } catch (e) {
      _saveNotification("Check-in error: $e");

      // Trigger vibration for error
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200); // Short vibration for error
      }

      // Play system ringtone for error
      _ringtonePlayer.play(
        fromAsset: "system/ringtone", // Use system ringtone
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: mainColor),
      );
    }
  }
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, double>?> _getBranchLocation(String companyEmail) async {
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
      if (data["status"] == "SUCCESS" && data["branches"].isNotEmpty) {
        var branch = data["branches"].first;
        return {
          "latitude": double.parse(branch["latitude"]),
          "longitude": double.parse(branch["longitude"]),
        };
      }
    }

    return null;
  }

  Future<void> _clockout(String email, String companyEmail) async {
    var url = Uri.parse(
      'http://65.21.59.117/safe-business-api/public/api/v1/employeeClockOut',
    );

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "employeeEmail": email,
          "companyEmail": companyEmail,
        }),
      );

      var responseData = jsonDecode(response.body);
      print("Response: $responseData");

      if (response.statusCode == 200) {
        if (responseData["status"] == "SUCCESS") {
          _saveNotification("Check-out successful");

          // Trigger vibration
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 500); // Vibrate for 500ms
          }

          // Play system notification sound
          _ringtonePlayer.playNotification();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Check-out success"),
              backgroundColor: Colors.green,
            ),
          );
          print("Clock-out successful!");
        } else {
          _saveNotification("Check-out failed: ${responseData["message"]}");

          // Trigger vibration for failure
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 200); // Short vibration for failure
          }

          // Play system alarm sound for failure
          _ringtonePlayer.play(
            fromAsset: "system/alarm", // Use system alarm sound
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Check-out failed! No Checkin found"),
              backgroundColor: mainColor,
            ),
          );
          print("Clock-out failed: ${responseData["message"]}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(
                  18.0,
                ),// Adjust the value as needed
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: const ShapeDecoration(
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30),
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 30,
                      left: 20,
                      right: 20,
                      bottom: 30,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/image 15.png'),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  verticalSpacing(30),
                                  _headerText('Employee Name'),
                                  _headerTextBold(employeeName),
                                  verticalSpacing(20),
                                   _headerText('Employee ID'),
                                  _headerTextBold(employeeId),
                                ],
                              ),
                      Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                verticalSpacing(30),
                                SizedBox(
                                    width: 59,
                                    height: 36,
                                    child: Transform.scale(
              scale: 1.8,
              child: Image.asset('assets/icons/qr-code2.png', color: mainColor,),
            ),
                                ),
                                verticalSpacing(5),
                               /* Text(
                                  'CheckInPro',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF646464),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )*/
                              ],
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),
                   /* Positioned(
                      bottom: 10,
                      right: 80,
                      child: SizedBox(
                        width: 55,
                        height: 55,
                       child: Image.asset(
                          'assets/icons/qr-code2.png',
                          color: Colors.white,
                        ),
                      ),
                    ),*/
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: SizedBox(width: 119, height: 119),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 30,
                  bottom: 15,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        actionButton(
                          context,
                          onPressed: () async {
                            final scannedEmail = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const QRCodeScanner(
                                      isReturningUser: true,
                                    ),
                              ),
                            );

                            if (scannedEmail != null &&
                                isValidEmail(scannedEmail)) {
                              _clockin(employeeEmail, companyEmail);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Invalid QR code! No company email found.",
                                  ),
                                  backgroundColor: mainColor,
                                ),
                              );
                            }
                          },
                          text: 'Check In', color: Colors.green,
                        ),
                        actionButton(
                          context,
                          onPressed: () async {
                            final scannedEmail = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const QRCodeScanner(
                                      isReturningUser: true,
                                    ),
                              ),
                            );

                            if (scannedEmail != null &&
                                isValidEmail(scannedEmail)) {
                              _clockout(employeeEmail, companyEmail);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Invalid QR code! No company email found.",
                                  ),
                                  backgroundColor: mainColor,
                                ),
                              );
                            }
                          },
                          text: 'Check Out', color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Adverts',
            style: GoogleFonts.poppins(
              color: Colors.blueGrey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryBox(
                title: 'Travels',
                icon: Icons.flight_takeoff,
                color: Colors.blueAccent, index: 0, image: AssetImage('assets/images/travel.jpeg'), // Provide image,
                
              ),
              _buildCategoryBox(
                title: 'Hangouts',
                icon: Icons.people,
                color: Colors.green, index: 1, image: AssetImage('assets/images/hangouts.jpg'), // Provide image,
              ),
              _buildCategoryBox(
                title: 'Vacations',
                icon: Icons.beach_access,
                color: Colors.orangeAccent, index: 2, image: AssetImage('assets/images/vacations.webp'), // Provide image,
              ),
              _buildCategoryBox(
                title: 'Food',
                icon: Icons.fastfood,
                color: Colors.pink, index: 3, image: AssetImage('assets/images/food.jpg'), // Provide image,
              ),
            ],
          ),
        ),
        /*verticalSpacing(10),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 5),
                child: Text(
                  'Adverts',
                  style: GoogleFonts.poppins(
                    color: Colors.blueGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),*/
              verticalSpacing(10),
              const Padding(
                padding: EdgeInsets.only(left: 18, right: 18, bottom: 15),
                child: ImageCarousel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InkWell actionButton(
  BuildContext context, {
  required Function() onPressed,
  required String text,
  required Color color, // Add a color parameter
}) {
  return InkWell(
    onTap: onPressed,
    splashColor: color.withOpacity(0.2), // Use the passed color for splash effect
    highlightColor: color.withOpacity(0.1), // Use the passed color for highlight effect
    borderRadius: BorderRadius.circular(10), // Match the border radius of the container
    child: Ink(
      width: MediaQuery.of(context).size.width * 0.4,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color, // Use the passed color for the border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1), // Use the passed color for the shadow
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.black, // Keep text color black
            fontSize: 14,
            fontWeight: FontWeight.w600, // Slightly bolder text
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCategoryBox({
  required int index,
  required String title,
  required IconData icon,
  required Color color,
  ImageProvider? image, // Make image optional
}) {
  bool isSelected = selectedIndex == index; // Check if this box is selected

  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index; // Update the selected index
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: isSelected ? 120 : 110, // Increase height when selected
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.8) : color, // Highlight selected box
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.15), // Stronger shadow for selected
              blurRadius: isSelected ? 8 : 5,
              offset: Offset(0, isSelected ? -2 : 4), // Lift effect
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null) 
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Icon(icon, size: 32, color: Colors.white), // Show icon if no image

            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _headerText(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF646464),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF646464),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
