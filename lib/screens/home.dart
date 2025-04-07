import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:safebusiness/screens/QRCodeScanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/carousel.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String companyName = "";
  int selectedIndex = -1; // Initially, no box is selected
  late Future<bool> _canCheckIn;
  late Future<bool> _canCheckOut;
  File? _imageFile;
  String? _imagePath;


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
     _loadStates();
     _loadSavedImage();
  }

  /// Load the saved image path from SharedPreferences
  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('profile_image');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _imageFile = File(savedPath);
        _imagePath = savedPath;
      });
    }
  }

  /// Pick an image from the gallery and save it to app storage
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File savedImage = await _saveImageToAppStorage(File(pickedFile.path));
      setState(() {
        _imageFile = savedImage;
        _imagePath = savedImage.path;
      });
      _saveImagePath(savedImage.path); // Save image path in SharedPreferences
    }
  }

  /// Save the picked image to the app's internal storage
  Future<File> _saveImageToAppStorage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory(); // App's storage
    final savedImagePath = '${appDir.path}/profile_image.jpg';
    return imageFile.copy(savedImagePath); // Copy the image
  }

  /// Save the selected image path to SharedPreferences
  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', path);
  }

  Future<void> _loadEmployeeDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeId = prefs.getString('employeeId') ?? "N/A";
      employeeName = prefs.getString('employeeName') ?? "N/A";
      employeeEmail = prefs.getString('email') ?? "N/A";
      companyEmail = prefs.getString('companyEmail') ?? "N/A";
      companyName = prefs.getString('companyName') ?? "N/A";
    });
  }

  void _loadStates() {
    _canCheckIn = CheckInOutManager.isCheckedIn().then((value) => !value);
    _canCheckOut = CheckInOutManager.isCheckedOut().then((value) => !value);
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

  Future<bool> _clockin(String email, String companyEmail) async {
  if (!mounted) return false;

  /*Position? userPosition = await _determinePosition();
  if (userPosition == null) {
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unable to determine location, Please turn on your location"),
        backgroundColor: mainColor,
      ),
    );
    _saveNotification("Check-in failed: Unable to determine location");
    return false;
  }

  double userLatitude = userPosition.latitude;
  double userLongitude = userPosition.longitude;

  var branchLocation = await _getBranchLocation(companyEmail);
  if (branchLocation == null || branchLocation['latitude'] == null || branchLocation['longitude'] == null) {
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Branch location not found, Please try again"),
        backgroundColor: mainColor,
      ),
    );
    _saveNotification("Check-in failed: Branch location not found");
    return false;
  }

  double? branchLatitude = branchLocation['latitude'];
  double? branchLongitude = branchLocation['longitude'];

  double distanceInMeters = Geolocator.distanceBetween(
    userLatitude,
    userLongitude,
    branchLatitude!,
    branchLongitude!,
  );

  if (distanceInMeters < 20) {
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You are too far from your branch to check in"),
        backgroundColor: mainColor,
      ),
    );
    _saveNotification("Check-in failed: Too far from branch");
    return false;
  }*/

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
        //"latitude": userLatitude,
        //"longitude": userLongitude,
      }),
    );

    var responseData = jsonDecode(response.body);
    print("Check-in Response: $responseData");

    String message = responseData["message"] ?? "Unknown error occurred";

    if (response.statusCode == 200 && responseData["status"] == "SUCCESS") {
      _saveNotification("Check-in successful");

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 500);
      }
      _ringtonePlayer.playNotification();

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Check-in success"),
          backgroundColor: Colors.green,
        ),
      );
      return true; // Indicate success
    } else {
      _saveNotification("Check-in failed: $message");

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
      _ringtonePlayer.play(fromAsset: "system/alarm");

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Check-in failed: $message"),
          backgroundColor: mainColor,
        ),
      );
      return false; // Indicate failure
    }
  } catch (e) {
    _saveNotification("Check-in error: $e");

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 200);
    }
    _ringtonePlayer.play(fromAsset: "system/ringtone");

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: mainColor),
    );
    return false; // Indicate failure
  }
}

 /* Future<Position?> _determinePosition() async {
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
  }*/

  Future<bool> _clockout(String email, String companyEmail) async {
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
    print("Check-out Response: $responseData");

    if (response.statusCode == 200 && responseData["status"] == "SUCCESS") {
      _saveNotification("Check-out successful");

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 500);
      }
      _ringtonePlayer.playNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Check-out success"),
          backgroundColor: Colors.green,
        ),
      );
      return true; // Indicate success
    } else {
      _saveNotification("Check-out failed: ${responseData["message"]}");

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
      _ringtonePlayer.play(fromAsset: "system/alarm");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Check-out failed: ${responseData["message"]}"),
          backgroundColor: mainColor,
        ),
      );
      return false; // Indicate failure
    }
  } catch (e) {
    print("Error: $e");
    return false; // Indicate failure
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
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.30,
              decoration: const ShapeDecoration(
                color: mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              key: UniqueKey(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
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
                                verticalSpacing(15),
                                _headerTextBold(companyName),
                                verticalSpacing(10),
                                _headerText('Employee Name'),
                                _headerTextBold(employeeName),
                                verticalSpacing(10),
                                _headerText('Employee ID'),
                                _headerTextBold(employeeId),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                //verticalSpacing(5),
                                SizedBox(
                                    width: 59,
                                    height: 36,
                                    child:
                                        Image.asset('assets/icons/checkinprowhite.png')),
                                //verticalSpacing(5),
                                Text(
                                  'CheckInPro',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF646464),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
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
                        child: Image.asset('assets/icons/qr-code2.png',
                            color: Colors.white),
                      )),*/
                  // put a circle avatar here
                  Positioned(
  bottom: -60,
  left: 0,
  right: 0,
  child: GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200], // Background color for the icon
        border: Border.all(
          color: Colors.grey.shade400,
          width: 2,
        ),
        image: _imageFile != null
            ? DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              )
            : null, // No default image
      ),
      child: _imageFile == null
          ? const Center(
              child: Icon(
                Icons.camera_alt, // Your preferred icon
                size: 40,
                color: Colors.grey,
              ),
            )
          : null,
    ),
  ),
),
                ],
              ), // Forces a rebuild when the image changes
            ),
            verticalSpacing(MediaQuery.of(context).size.height * 0.05),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 15),
                child: FutureBuilder(
                  future: Future.wait([_canCheckIn, _canCheckOut]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var canCheckIn = snapshot.data![0];
                    var canCheckOut = snapshot.data![1];

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Check In Button
                        GestureDetector(
  onTap: canCheckIn ? () async {
  final scannedEmail = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const QRCodeScanner(isReturningUser: true),
    ),
  );

  if (scannedEmail != null && isValidEmail(scannedEmail)) {
    bool success = await _clockin(employeeEmail, companyEmail);
    if (success) {
      await CheckInOutManager.setCheckedIn(true); // Update shared prefs
      setState(() {
        _loadStates(); // Reload Future values to update UI
      });
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invalid QR code!"),
        backgroundColor: mainColor,
      ),
    );
  }
} : null, // Disable button when canCheckIn is false


                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: MediaQuery.of(context).size.width * 0.42,
                            height: 50,
                            decoration: BoxDecoration(
                              color: canCheckIn ? Colors.green[600] : Colors.grey[400],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: canCheckIn ? [
                                BoxShadow(
                                  color: Colors.green[800]!.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                'CHECK IN',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Check Out Button
                        GestureDetector(
  onTap: canCheckOut ? () async {
  final scannedEmail = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const QRCodeScanner(isReturningUser: true),
    ),
  );

  if (scannedEmail != null && isValidEmail(scannedEmail)) {
    bool success = await _clockout(employeeEmail, companyEmail);
    if (success) {
      await CheckInOutManager.setCheckedOut(true); // Update shared prefs
      setState(() {
        _loadStates(); // Reload Future values to update UI
      });
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invalid QR code!"),
        backgroundColor: mainColor,
      ),
    );
  }
} : null, // Disable button when canCheckOut is false
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: MediaQuery.of(context).size.width * 0.42,
                            height: 50,
                            decoration: BoxDecoration(
                              color: canCheckOut ? Colors.blue[600] : Colors.grey[400],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: canCheckOut ? [
                                BoxShadow(
                                  color: Colors.blue[800]!.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                'CHECK OUT',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adverts',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios, // Right arrow
                color: Colors.blueGrey,
                size: 16,
              ),
            ],
          ),
        ),

        // Horizontal scrollable category boxes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryBox(
                  title: 'Travels',
                  icon: Icons.flight_takeoff,
                  color: Colors.blueAccent,
                  index: 0,
                  image: AssetImage('assets/images/travel.jpeg'),
                ),
                _buildCategoryBox(
                  title: 'Hangouts',
                  icon: Icons.people,
                  color: Colors.green,
                  index: 1,
                  image: AssetImage('assets/images/hangouts.jpg'),
                ),
                _buildCategoryBox(
                  title: 'Vacations',
                  icon: Icons.beach_access,
                  color: Colors.orangeAccent,
                  index: 2,
                  image: AssetImage('assets/images/vacations.webp'),
                ),
                // More categories can be added here
                _buildCategoryBox(
                  title: 'Food',
                  icon: Icons.fastfood,
                  color: Colors.pink,
                  index: 3,
                  image: AssetImage('assets/images/food.jpg'),
                ),

                _buildCategoryBox(
                  title: 'Health',
                  icon: Icons.fastfood,
                  color: Colors.redAccent,
                  index: 3,
                  image: AssetImage('assets/images/health.jpeg'),
                ),

                _buildCategoryBox(
                  title: 'Spirituality',
                  icon: Icons.fastfood,
                  color: Colors.yellowAccent,
                  index: 3,
                  image: AssetImage('assets/images/spiritual.jpg'),
                ),
                // Add more categories as needed
              ],
            ),
          ),
        ),

        // Spacer or additional content if needed
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 15),
          child: ImageCarousel(), // Custom widget for carousel (if needed)
        ),
            ],
          ),
        ),
      ),
    );
  }

  /*InkWell actionButton(
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
}*/

  Widget _buildCategoryBox({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    ImageProvider? image, // Make image optional
  }) {
    bool isSelected = selectedIndex == index; // Check if this box is selected

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index; // Update the selected index
        });
      },
      child: Container(
        width: 110, // Limit width of each category box
        height: 110,
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


class CheckInOutManager {
  static const _checkInKey = 'isCheckedIn';
  static const _checkOutKey = 'isCheckedOut';

  static Future<void> setCheckedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checkInKey, value);
    if (value) {
      await prefs.setBool(_checkOutKey, false);
    }
  }

  static Future<void> setCheckedOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checkOutKey, value);
    if (value) {
      await prefs.setBool(_checkInKey, false);
    }
  }

  static Future<bool> isCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_checkInKey) ?? false;
  }

  static Future<bool> isCheckedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_checkOutKey) ?? false;
  }

  static Future<void> resetStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInKey);
    await prefs.remove(_checkOutKey);
  }
}
