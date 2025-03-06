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
import 'package:add_2_calendar/add_2_calendar.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  String employeeId = "";
  String employeeName = "";
  String employeeEmail = "";
  String companyEmail = "";

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
    String timestamp = DateFormat('hh:mm a EEE MMM d, y').format(DateTime.now());
    notifications.insert(0, "$message - $timestamp");
    await prefs.setStringList('notifications', notifications);
  }

  Future<void> _clockin(String email, String companyEmail) async {
    if (!mounted) return;

    Position? userPosition = await _determinePosition();
    if (userPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to determine location"), backgroundColor: Colors.red),
      );
      _saveNotification("Check-in failed: Unable to determine location");
      return;
    }

    double userLatitude = userPosition.latitude;
    double userLongitude = userPosition.longitude;

    var branchLocation = await _getBranchLocation(companyEmail);
    if (branchLocation == null || branchLocation['latitude'] == null || branchLocation['longitude'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Branch location not found"), backgroundColor: Colors.red),
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
        SnackBar(content: Text("You are too far from your branch to check in"), backgroundColor: Colors.red),
      );
      _saveNotification("Check-in failed: Too far from branch");
      return;
    }

    var url = Uri.parse('http://65.21.59.117/safe-business-api/public/api/v1/employeeClockIn');

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Check-in success"), backgroundColor: Colors.green),
        );
      } else {
        _saveNotification("Check-in failed: $message");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Check-in failed: $message"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      _saveNotification("Check-in error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
          print("Check-out success");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Check-out success"),
              backgroundColor: Colors.green,
            ),
          );
          print("Clock-out successful!");
        } else {
          _saveNotification("Check-out failed: ${responseData["message"]}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Check-out failed!"),
              backgroundColor: Colors.red,
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


Future<void> _addCheckoutReminder(DateTime checkoutTime) async {
  final Event event = Event(
    title: 'Checkout Reminder',
    description: 'Don’t forget to check out!',
    startDate: checkoutTime,
    endDate: checkoutTime.add(const Duration(minutes: 30)), // Optional: Event duration
    iosParams: const IOSParams(reminder: Duration(minutes: 30)), // Reminder 30 minutes before the event
    androidParams: const AndroidParams(
      emailInvites: [], // Optional: Add email invites if needed
    ),
  );

  await Add2Calendar.addEvent2Cal(event);
}

Future<void> _selectCheckoutTime(BuildContext context) async {
  DateTime now = DateTime.now();
  DateTime? selectedTime = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: DateTime(now.year + 1),
  );

  if (selectedTime != null) {
    TimeOfDay? selectedHour = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedTime),
    );

    if (selectedHour != null) {
      // Combine the selected date and time
      DateTime checkoutDateTime = DateTime(
        selectedTime.year,
        selectedTime.month,
        selectedTime.day,
        selectedHour.hour,
        selectedHour.minute,
      );

      // Add the reminder to the calendar
      await _addCheckoutReminder(checkoutDateTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout reminder set for ${DateFormat.jm().format(checkoutDateTime)}")),
      );
    }
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
                margin: const EdgeInsets.all(16.0), // Adjust the value as needed
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.38,
                decoration: const ShapeDecoration(
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 40,
                      left: 40,
                      right: 40,
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
                          borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  verticalSpacing(30),
                                  _headerText('Employee ID'),
                                  _headerTextBold(employeeId),
                                  verticalSpacing(20),
                                  _headerText('Employee Name'),
                                  _headerTextBold(employeeName),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  verticalSpacing(30),
                                  SizedBox(
                                    width: 59,
                                    height: 36,
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                    ),
                                  ),
                                  verticalSpacing(5),
                                  Text(
                                    'Nard Concepts',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF646464),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
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
                    ),
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        width: 119,
                        height: 119,
                      ),
                    ),
                  ],
                ),
              ),
              //verticalSpacing(MediaQuery.of(context).size.height * 0.07),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 30,
                  bottom: 15),
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
                                builder: (context) => const QRCodeScanner(isReturningUser: true),
                              ),
                            );

                            if (scannedEmail != null && isValidEmail(scannedEmail)) {
                              _clockin(employeeEmail, companyEmail);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Invalid QR code! No company email found."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          text: 'Check In',
                        ),
                        actionButton(
                          context,
                          onPressed: () async {
                            final scannedEmail = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRCodeScanner(isReturningUser: true),
                              ),
                            );

                            if (scannedEmail != null && isValidEmail(scannedEmail)) {
                              _clockout(employeeEmail, companyEmail);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Invalid QR code! No company email found."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          text: 'Check Out',
                        ),
                      ],
                    ),
                    verticalSpacing(10),
                  /*  actionButton(
        context,
        onPressed: () async {
          await _selectCheckoutTime(context);
        },
        text: 'Set Checkout Reminder',
      ),*/
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 5),
                child: Text(
                  'Adverts',
                  style: GoogleFonts.poppins(
                    color: black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
  }) {
    return InkWell(
      onTap: onPressed,
      splashColor: mainColor.withOpacity(0.2),
      highlightColor: mainColor.withOpacity(0.2),
      child: Ink(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 44,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: mainColor),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: mainColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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