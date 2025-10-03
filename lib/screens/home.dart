import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safebusiness/screens/EmailQRScreen.dart';
import 'package:safebusiness/screens/FaceRec/Face_checkin.dart';
import 'package:safebusiness/screens/QRCodeScanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safebusiness/screens/notification.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/carousel.dart';
import 'package:safebusiness/widgets/carousel_image.dart';
import 'package:safebusiness/widgets/carousels.dart';
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
  final String qrData = "EMP-2023-0012-John-Doe";
  String employeeId = "";
  String employeeName = "";
  String employeeEmail = "";
  String companyEmail = "";
  String companyName = "";
  String branchName = "";
  String departmentName = "";
  String designationName = "";
  int selectedIndex = -1; // Initially, no box is selected
  late Future<bool> _canCheckIn;
  late Future<bool> _canCheckOut;
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = false;
  String? selectedCategory;
  final List<String> defaultImages = [
    "assets/images/westminister.jpg",
    "assets/images/hcash1.jpg",
    //'assets/images/image6.jpg',
  ];

  final categoryData = [
    {'title': 'Nard Concepts', 'imagePath': 'assets/images/logo.png'},
    {'title': 'Payments', 'imagePath': 'assets/images/westminister.jpg'},
    {'title': 'Health', 'imagePath': 'assets/images/health.jpeg'},
    {'title': 'Travels', 'imagePath': 'assets/images/travel.jpeg'},
    {'title': 'Vacations', 'imagePath': 'assets/images/vac.jpg'},
    {'title': 'Hangouts', 'imagePath': 'assets/images/hangouts.jpg'},
    {'title': 'Food', 'imagePath': 'assets/images/food.jpg'},
    {'title': 'Events', 'imagePath': 'assets/images/events.jpg'},
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService(context).init(); // 🔥 RUN IN BACKGROUND
    });
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

  Future<void> _fetchBranchName(int branchId) async {
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
      if (data["status"] == "SUCCESS") {
        var branch = (data["branches"] as List).firstWhere(
          (b) => b["id"] == branchId,
          orElse: () => null,
        );
        setState(() {
          branchName = branch != null ? branch["name"] : "Unknown Branch";
        });
      }
    }
  }

  Future<void> _fetchDepartmentName(int branchId, int departmentId) async {
    var url = Uri.parse(
      "http://65.21.59.117/safe-business-api/public/api/v1/getCompanyDepartmentsByBranch",
    );
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"companyEmail": companyEmail, "branchId": branchId}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS") {
        var department = (data["departments"] as List).firstWhere(
          (d) => d["id"] == departmentId,
          orElse: () => null,
        );
        setState(() {
          departmentName =
              department != null ? department["name"] : "Unknown Department";
        });
      }
    }
  }

  Future<void> _fetchDesignationName(
    int departmentId,
    int designationId,
  ) async {
    var url = Uri.parse(
      "http://65.21.59.117/safe-business-api/public/api/v1/getDesignationsByDepartment",
    );
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "companyEmail": companyEmail,
        "departmentId": departmentId,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS") {
        var designation = (data["designations"] as List).firstWhere(
          (d) => d["id"] == designationId,
          orElse: () => null,
        );
        setState(() {
          designationName =
              designation != null ? designation["name"] : "Unknown Designation";
        });
      }
    }
  }

  Future<void> _loadEmployeeDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int branchId = prefs.getInt("branchId") ?? 0;
    int departmentId = prefs.getInt("departmentId") ?? 0;
    int designationId = prefs.getInt("designationId") ?? 0;
    setState(() {
      employeeId = prefs.getString('employeeId') ?? "N/A";
      employeeName = prefs.getString('employeeName') ?? "N/A";
      employeeEmail = prefs.getString('email') ?? "N/A";
      companyEmail = prefs.getString('companyEmail') ?? "N/A";
      companyName = prefs.getString('companyName') ?? "N/A";
    });
    _fetchBranchName(branchId);
    _fetchDepartmentName(branchId, departmentId);
    _fetchDesignationName(departmentId, designationId);
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
          content: Text(
            "Unable to determine location, Please turn on your location",
          ),
          backgroundColor: mainColor,
        ),
      );
      print("Unable to determine location, Please turn on your location");
      _saveNotification("Check-in failed: Unable to determine location");
      return false;
    }

    double userLatitude = userPosition.latitude;
    double userLongitude = userPosition.longitude;

    var branchLocation = await _getBranchLocation(companyEmail);
    if (branchLocation == null ||
        branchLocation['latitude'] == null ||
        branchLocation['longitude'] == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Branch location not found, Please try again"),
          backgroundColor: mainColor,
        ),
      );
      print("Branch location not found, Please try again");
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

    if (distanceInMeters > 100) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are too far from your branch to check in"),
          backgroundColor: mainColor,
        ),
      );
      print("You are too far from your branch to check in");
      _saveNotification("Check-in failed: Too far from branch");
      return false;
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
        print("✅checkin successful");
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
      print("Error during check-in: $e"); // Log the error
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
        print("Location permission denied."); // Log the error
        return null;
      }

      if (permission == LocationPermission.denied) {
        print("Location permission denied."); // Log the error
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

    print("Branch Location Response: ${response.body}");

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS" && data["branches"].isNotEmpty) {
        var branch = data["branches"].first;
        if (branch["latitude"] != null && branch["longitude"] != null) {
        return {
          "latitude": double.parse(branch["latitude"]),
          "longitude": double.parse(branch["longitude"]),
        };
      } else {
        print("Branch coordinates are missing (latitude/longitude is null).");
        return null; // ✅ Handle missing coordinates
      }
    }
  }
  return null;
}

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
        //backgroundColor: Colors.white,
        /*appBar: AppBar(
        title: Text('Employee Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),*/
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                   delay: Duration(milliseconds: 100),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const ShapeDecoration(
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Profile Picture
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: () async {
                                if (_isLoading) return;
                                setState(() {
                                  _isLoading = true;
                                });
                                await _pickImage();
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[100],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  image:
                                      _imageFile != null
                                          ? DecorationImage(
                                            image: FileImage(_imageFile!),
                                            fit: BoxFit.cover,
                                          )
                                          : const DecorationImage(
                                            image: NetworkImage(
                                              'https://randomuser.me/api/portraits/men/1.jpg',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                ),
                                child:
                                    _isLoading
                                        ? const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : (_imageFile == null
                                            ? Center(
                                              child: Icon(
                                                Icons.camera_alt,
                                                size: 30,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            )
                                            : null),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Name and Employee ID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employeeName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  employeeId,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmailQrScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.qr_code,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Department',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                departmentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Designation',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                designationName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                   delay: Duration(milliseconds: 100),
                    // Personal Info Card
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          children: [
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            FutureBuilder(
                              future: Future.wait([_canCheckIn, _canCheckOut]),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                var canCheckIn = snapshot.data![0];
                                var canCheckOut = snapshot.data![1];

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Check In Button
                                    GestureDetector(
                                      onTap:
                                          canCheckIn
                                              ? () async {
                                                // 1️⃣ Navigate to QR Scanner First
                                                final scannedEmail =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => const QRCodeScanner(
                                                              isReturningUser:
                                                                  true,
                                                            ),
                                                      ),
                                                    );

                                                // 2️⃣ If QR Scan Successful
                                                if (scannedEmail != null &&
                                                    isValidEmail(
                                                      scannedEmail,
                                                    )) {
                                                  await Future.delayed(
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                  );
                                                  // 3️⃣ Navigate to Face Detection Page
                                                  final faceCheckPassed =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const FaceCheckInPage(),
                                                        ),
                                                      );

                                                  // 4️⃣ If Face Matches → Perform Check-in
                                                  if (faceCheckPassed == true) {
                                                    bool success =
                                                        await _clockin(
                                                          employeeEmail,
                                                          companyEmail,
                                                        );
                                                    if (success) {
                                                      await CheckInManager.setCheckedIn(
                                                        true,
                                                      );
                                                      setState(() {
                                                        _loadStates(); // Reload UI
                                                      });
                                                    }
                                                  } else {
                                                    // ScaffoldMessenger.of(
                                                    //   context,
                                                    // ).showSnackBar(
                                                    //   const SnackBar(
                                                    //     content: Text(
                                                    //       "Face verification failed!",
                                                    //     ),
                                                    //     backgroundColor:
                                                    //         Colors.red,
                                                    //   ),
                                                    // );
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Invalid QR code!",
                                                      ),
                                                      backgroundColor:
                                                          mainColor,
                                                    ),
                                                  );
                                                }
                                              }
                                              : null, // Disable button when canCheckIn is false

                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.42,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 0.5,
                                          ),
                                          gradient:
                                              canCheckIn
                                                  ? const LinearGradient(
                                                    colors: [
                                                      Color(
                                                        0xFF4B0000,
                                                      ), // Deep Burgundy
                                                      Color(
                                                        0xFFF80101,
                                                      ), // Dark Red
                                                      Color(
                                                        0xFF8B0000,
                                                      ), // Crimson/Dark Red
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                  : LinearGradient(
                                                    colors: [
                                                      Colors.grey,
                                                      Colors.grey,
                                                    ],
                                                  ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .login, // Checkout-style icon
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
                                    SizedBox(width: 8),

                                    // Check Out Button
                                    GestureDetector(
                                      onTap:
                                          canCheckOut
                                              ? () async {
                                                final scannedEmail =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => const QRCodeScanner(
                                                              isReturningUser:
                                                                  true,
                                                            ),
                                                      ),
                                                    );

                                                if (scannedEmail != null &&
                                                    isValidEmail(
                                                      scannedEmail,
                                                    )) {
                                                  await Future.delayed(
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                  );
                                                  // 3️⃣ Navigate to Face Detection Page
                                                  final faceCheckPassed =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const FaceCheckInPage(),
                                                        ),
                                                      );
                                                  if (faceCheckPassed == true) {
                                                    bool success =
                                                        await _clockout(
                                                          employeeEmail,
                                                          companyEmail,
                                                        );
                                                    if (success) {
                                                      await CheckOutManager.setCheckedOut(
                                                        true,
                                                      );
                                                      setState(() {
                                                        _loadStates(); // Reload Future values to update UI
                                                      });
                                                    }
                                                  } else {
                                                    if (mounted) return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Invalid QR code!",
                                                        ),
                                                        backgroundColor:
                                                            mainColor,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                              : null,

                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.42,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 0.5,
                                          ),
                                          gradient:
                                              canCheckOut
                                                  ? const LinearGradient(
                                                    colors: [
                                                      Color(
                                                        0xFF4B0000,
                                                      ), // Deep Burgundy
                                                      Color(
                                                        0xFFF80101,
                                                      ), // Dark Red
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .logout, // Checkout-style icon
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
                            SizedBox(height: 14),
                            Text(
                              'Mark your Attendance here',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
                    SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                   delay: Duration(milliseconds: 100),
                    child: Padding(
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
                              color: mainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios, // Right arrow
                            color: mainColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    ),
                    // Horizontal scrollable category boxes
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                   delay: Duration(milliseconds: 100),
                    child: Padding(
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
                                setState(() {
                                  selectedCategory =
                                      categoryData[index]['title'] as String;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6.4,
                                  horizontal: 10,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 107,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 0.4,
                                  ),
                                  image: DecorationImage(
                                    image: AssetImage(
                                      categoryData[index]['imagePath']
                                          as String,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Container(
                                  color: Colors.black.withOpacity(
                                    0.5,
                                  ), // dark overlay for readability
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    categoryData[index]['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              /*child: Container(
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
          ),*/
                            );
                          },
                        ),
                      ),
                    ),
                    ),

                    // Spacer or additional content if needed
                    SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                   delay: Duration(milliseconds: 100),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                        right: 18,
                        bottom: 15,
                      ),
                      child: ImageCarosel(
                        imageList:
                            selectedCategory != null &&
                                    categoryImages[selectedCategory!] != null
                                ? categoryImages[selectedCategory!]!
                                : defaultImages,
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      await prefs.setInt(
        _checkedInTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
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
      await prefs.setInt(
        _checkedOutTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
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
