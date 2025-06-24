import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:safebusiness/screens/EmailQRScreen.dart';
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
  bool _isLoading = false;
  final categoryData = [
  {
    'title': 'Health',
    'desc': 'Wellbeing',
    'icon': Icons.health_and_safety,
    'index': 3,
  },
  {
    'title': 'Travels',
    'desc': 'Explore',
    'icon': Icons.flight_takeoff,
    'index': 0,
  },
  {
    'title': 'Vacations',
    'desc': 'Relaxation',
    'icon': Icons.beach_access,
    'index': 2,
  },
  {
    'title': 'Hangouts',
    'desc': 'Social Fun',
    'icon': Icons.people,
    'index': 1,
  },
  {
    'title': 'Food',
    'desc': 'Tastes',
    'icon': Icons.fastfood,
    'index': 3,
  },
  {
    'title': 'Spirituality',
    'desc': 'Peace',
    'icon': Icons.self_improvement,
    'index': 3,
  },
];


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
  bool _isPicking = false;

  Future<void> _pickImage() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        File savedImage = await _saveImageToAppStorage(File(pickedFile.path));
        setState(() {
          _imageFile = savedImage;
          _imagePath = savedImage.path;
        });
        _saveImagePath(savedImage.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    } finally {
      _isPicking = false;
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
  _canCheckIn = CheckInManager.isCheckedIn().then((value) => !value);
  _canCheckOut = CheckOutManager.isCheckedOut().then((value) => !value);
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

    Position? userPosition = await _determinePosition();
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

  /*var branchLocation = await _getBranchLocation(companyEmail);
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
          "latitude": userLatitude,
          "longitude": userLongitude,
        }),
      );

      var responseData = jsonDecode(response.body);
      print("Check-in Response: $responseData");

      String message = responseData["message"] ?? "Unknown error occurred";

      if (response.statusCode == 200 && responseData["status"] == "SUCCESS") {
        _saveNotification("Check-in successful");
        await CheckInManager.setCheckedIn(true);
        await CheckOutManager.setCheckedOut(false);

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

  /*Future<Map<String, double>?> _getBranchLocation(String companyEmail) async {
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
        await CheckInManager.setCheckedIn(false); // ✅ Reset check-in status
        await CheckOutManager.setCheckedOut(true);

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
        backgroundColor: mainColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
  width: double.infinity,
  height: MediaQuery.of(context).size.height * 0.36,
  decoration: const ShapeDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF4B0000),
        Color(0xFFF80101),
        Color(0xFF8B0000),
      ],
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(
          child: Text(
            companyName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerText('Employee Name'),
                  _headerTextBold(employeeName),
                  verticalSpacing(5),
                  //SizedBox(height: 6),
                  _headerText('Employee ID'),
                  _headerTextBold(employeeId),
                  //SizedBox(height: 12),
                  verticalSpacing(5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmailQrScreen()),
                      );
                    },
                    child: Row(
  children: [
    Container(
      width: 55,
      height: 55,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Image.asset(
        'assets/icons/qr-code2.png',
        color: Colors.white,
      ),
    ),
    const SizedBox(width: 10),
    Text(
      'Tap to get QR Code',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
  ],
),

                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 59,
                  height: 36,
                  child: Image.asset(
                    'assets/icons/checkin2.png',
                    color: Colors.white,
                  ),
                ),
                /*Text(
                  'CheckInPro',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),*/
              ],
            ),
          ],
        ),
      ],
    ),
  ),
),

              //verticalSpacing(MediaQuery.of(context).size.height * 0.05),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 30,
                  bottom: 15,
                ),
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
  onTap: canCheckIn
      ? () async {
          final scannedEmail = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRCodeScanner(
                isReturningUser: true,
              ),
            ),
          );

          if (scannedEmail != null && isValidEmail(scannedEmail)) {
            bool success = await _clockin(
              employeeEmail,
              companyEmail,
            );
            if (success) {
              await CheckInManager.setCheckedIn(true);
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
        }
      : null, // Disable button when canCheckIn is false

  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: MediaQuery.of(context).size.width * 0.42,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.white,
        width: 0.5,
      ),
      gradient: canCheckIn
          ? const LinearGradient(
  colors: [
    Color(0xFF4B0000), // Deep Burgundy
    Color(0xFFF80101), // Dark Red
    Color(0xFF8B0000), // Crimson/Dark Red
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

          : LinearGradient(
              colors: [
                Colors.grey[500]!,
                Colors.grey[500]!,
              ],
            ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.login, // Checkout-style icon
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'CHECK IN',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ),
  ),
),


                        // Check Out Button
                        GestureDetector(
  onTap: canCheckOut
      ? () async {
          final scannedEmail = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRCodeScanner(
                isReturningUser: true,
              ),
            ),
          );

          if (scannedEmail != null && isValidEmail(scannedEmail)) {
            bool success = await _clockout(
              employeeEmail,
              companyEmail,
            );
            if (success) {
              await CheckOutManager.setCheckedOut(true);
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
        }
      : null,

  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: MediaQuery.of(context).size.width * 0.42,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.white,
        width: 0.5,
      ),
      gradient: canCheckOut
          ? const LinearGradient(
              colors: [
                 Color(0xFF4B0000), // Deep Burgundy
    Color(0xFFF80101), // Dark Red
    Color(0xFF8B0000),
              ],
            )
          : LinearGradient(
              colors: [
                Colors.grey,
                Colors.grey,
              ],
            ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.logout, // Checkout-style icon
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'CHECK OUT',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ),
  ),
),

                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adverts',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios, // Right arrow
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Horizontal scrollable category boxes
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
    height: 100,
    child: ListView.builder(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(0),
      scrollDirection: Axis.horizontal,
      itemCount: categoryData.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // handle tap using categoryData[index]['index'] or other params
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6.4, horizontal: 10),
            constraints: BoxConstraints(
              minWidth: 107,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                   Color(0xFF4B0000), // Deep Burgundy
    Color(0xFFF80101), // Dark Red
    Color(0xFF8B0000),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 0.4),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
  categoryData[index]['icon'] as IconData,
  color: Colors.white,
  size: 32,
),

                ),
                SizedBox(height: 6),
                Text(
                  categoryData[index]['title'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  categoryData[index]['desc'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
),


              // Spacer or additional content if needed
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 15),
                child:
                    ImageCarousel(), // Custom widget for carousel (if needed)
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

 /* Widget _buildCategoryBox({
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
          color:
              isSelected
                  ? color.withOpacity(0.8)
                  : color, // Highlight selected box
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isSelected ? 0.3 : 0.15,
              ), // Stronger shadow for selected
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
                  image: DecorationImage(image: image, fit: BoxFit.cover),
                ),
              )
            else
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ), // Show icon if no image

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
  }*/

  Widget _headerText(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
}

class CheckInManager {
  static const String _checkedInKey = 'checked_in';
  static const String _checkedInTimeKey = 'checked_in_time';

  static Future<void> setCheckedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checkedInKey, value);
    if (value) {
      await prefs.setInt(_checkedInTimeKey, DateTime.now().millisecondsSinceEpoch);
    } else {
      await prefs.remove(_checkedInTimeKey);
    }
  }

  static Future<bool> isCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool? checkedIn = prefs.getBool(_checkedInKey);
    int? checkedInTime = prefs.getInt(_checkedInTimeKey);

    if (checkedIn == true && checkedInTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final diffInHours = (currentTime - checkedInTime) / (1000 * 60 * 60);

      // If more than 8 hours passed, reset check-in status
      if (diffInHours >= 8) {
        await prefs.setBool(_checkedInKey, false);
        await prefs.remove(_checkedInTimeKey);
        print('Check-in expired.');
        return false;
      }
    }

    return checkedIn ?? false;
  }
}


class CheckOutManager {
  static const String _checkedOutKey = 'checked_out';
  static const String _checkedOutTimeKey = 'checked_out_time';

  static Future<void> setCheckedOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checkedOutKey, value);
    if (value) {
      await prefs.setInt(_checkedOutTimeKey, DateTime.now().millisecondsSinceEpoch);
    } else {
      await prefs.remove(_checkedOutTimeKey);
    }
  }

  static Future<bool> isCheckedOut() async {
    final prefs = await SharedPreferences.getInstance();
    bool? checkedOut = prefs.getBool(_checkedOutKey);
    int? checkedOutTime = prefs.getInt(_checkedOutTimeKey);

    if (checkedOut == true && checkedOutTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final diffInHours = (currentTime - checkedOutTime) / (1000 * 60 * 60);

      // If more than 8 hours passed, reset check-out status
      if (diffInHours >= 8) {
        await prefs.setBool(_checkedOutKey, false);
        await prefs.remove(_checkedOutTimeKey);
        print('Check-out expired.');
        return false;
      }
    }

    return checkedOut ?? false;
  }
}
