import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
//import 'package:safebusiness/screens/Auth/gateman.dart';
import 'package:safebusiness/screens/Auth/location_access.dart';
import 'package:safebusiness/screens/change_pin.dart';
import 'package:safebusiness/screens/message.dart';
import 'package:safebusiness/screens/notify.dart';
import 'package:safebusiness/screens/password_input.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:safebusiness/widgets/gateman_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/custom_text_form_field.dart';
import '../../widgets/btm_nav_bar.dart';
import '../../widgets/sized_box.dart';
//import 'dart:io'; // Add this import at the top if not already present

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String routeName = "/login";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? storedEmployeeName; // Store employee name if already logged in
  String? storedEmployeeId;
  bool termsAccepted = true;
  //String selectedRole = 'Employee'; // default
  //String? selectedRole;
  //bool isRoleLocked = false;
  List announcements = [];
  String companyEmail = "";
  int branchId = 0;
  String branchName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredUser();
    _loadUserDetails();
    _fetchAnnouncements();
    //_loadSavedRole();
  }

  /*Future<void> _loadSavedRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedRole = prefs.getString('userRole');
    if (savedRole != null) {
      setState(() {
        selectedRole = savedRole;
        isRoleLocked = true;
      });
    }
  }*/

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

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userCompanyEmail = prefs.getString("companyEmail") ?? "N/A";

    int branchId = prefs.getInt("branchId") ?? 0;

    setState(() {
      companyEmail = userCompanyEmail;
    });

    // Fetch names asynchronously after UI update
    _fetchBranchName(branchId).then((_) {
      _fetchAnnouncements();
    });
  }

  /*Future<void> _fetchAnnouncements() async {
  try {
    print("Fetching announcements...");

    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyAnnouncementsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedAnnouncements");

    var body = jsonEncode(branchId > 0
        ? {"companyEmail": companyEmail, "branchId": branchId}
        : {"companyEmail": companyEmail});

    print("Request URL: $url");
    print("Request Body: $body");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS") {
        setState(() {
          announcements = data["announcements"] is List ? data["announcements"] : []; // Correct key here
          isLoading = false;
        });
        print("Announcements loaded: ${announcements.length}");
      } else {
        print("Unexpected API response: $data");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print("API Error: ${response.statusCode} - ${response.body}");
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    print("Fetch Announcements Error: $e");
    setState(() {
      isLoading = false;
    });
  }
}*/
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'announcement_channel',
          'Announcements',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      platformDetails,
      payload: 'announcement',
    );
  }

  Future<Set<String>> _getSeenAnnouncementIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('seenAnnouncements')?.toSet() ?? {};
  }

  Future<void> _saveSeenAnnouncementIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seenAnnouncements', ids.toList());
  }

  Future<void> _fetchAnnouncements() async {
    try {
      print("Fetching announcements...");

      var url =
          branchId > 0
              ? Uri.parse(
                "http://65.21.59.117/safe-business-api/public/api/v1/getCompanyAnnouncementsByBranch",
              )
              : Uri.parse(
                "http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedAnnouncements",
              );

      var body = jsonEncode(
        branchId > 0
            ? {"companyEmail": companyEmail, "branchId": branchId}
            : {"companyEmail": companyEmail},
      );

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS") {
          List fetched = data["announcements"] ?? [];

          print("Response Status Code: ${response.statusCode}");
          print("Response Body: ${response.body}");

          // Load seen announcements from storage
          Set<String> seenIds = await _getSeenAnnouncementIds();
          Set<String> newSeenIds = {...seenIds};

          for (var announcement in fetched) {
            String id = announcement['id'].toString();
            if (!seenIds.contains(id)) {
              await _showNotification(
                announcement['title'] ?? 'New Announcement',
                announcement['description'] ?? '',
              );
              newSeenIds.add(id);
            }
          }

          await _saveSeenAnnouncementIds(newSeenIds);

          setState(() {
            announcements = fetched;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print(
        "Fetch Announcements Error: Please check your internet connection (Wi-Fi or mobile data) and try again.",
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStoredUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedEmployeeName = prefs.getString('employeeName'); // Get stored name
      storedEmployeeId = prefs.getString('employeeid');
    });
  }

  Future<void> loginUser(String email, String password, String role) async {
    try {
      var url = Uri.parse(
        "http://65.21.59.117/safe-business-api/public/api/v1/loginUser",
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedEmail = prefs.getString('email'); // Retrieve stored email
      //await prefs.setString('userRole', role); // ← Save the chosen role

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": storedEmail ?? email, // Use stored email if available
          "password": password.trim(),
        }),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        //LateCheckInNotifier.checkAndSendLateSms();
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS") {
          // Store user details on first login
          if (storedEmail == null) {
            await prefs.setString('employeeId', data['employeeId'] ?? "N/A");
            await prefs.setString('employeeName', data['name'] ?? "N/A");
            await prefs.setString('email', data['email'] ?? "N/A");
            await prefs.setString('phone', data['phone'] ?? "N/A");
            await prefs.setString('address', data['address'] ?? "N/A");
            await prefs.setString('companyName', data['companyName'] ?? "N/A");
            await prefs.setInt('companyId', data['companyId'] ?? 0);
            await prefs.setString(
              'companyEmail',
              data['companyEmail'] ?? "N/A",
            );
            await prefs.setInt('branchId', data['branch_id'] ?? 0);
            await prefs.setInt('departmentId', data['department_id'] ?? 0);
            await prefs.setInt('designationId', data['designation_id'] ?? 0);
          }

          // Determine role based on email
          String effectiveEmail = storedEmail ?? email;
          bool isGateman = effectiveEmail.endsWith('@gateman.com');

          // Navigate to role-specific home
          if (isGateman) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => GatemanNavBar()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
            );
          }

          print("Login successful.");
        } else {
          _showError("Invalid email or PIN");
        }
      } else {
        _showError("Failed to login: ${response.statusCode}");
      }
    } catch (e) {
      _showError(
        "Error logging in: Please check your internet connection (Wi-Fi or mobile data) and try again.",
      );
    }
  }

  // Helper function to show errors
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Let the container handle the color
        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4B0000), // Deep Burgundy
                Color(0xFFF80101), // Dark Red
                Color(0xFF8B0000),
              ],
            ),
          ),
          child: Column(
            children: [
              verticalSpacing(MediaQuery.of(context).size.height * 0.10),
              Transform.scale(
                scale: 0.5,
                child: Image.asset('assets/icons/checkin2.png'),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.06),
              Text(
                'Login',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              verticalSpacing(20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            verticalSpacing(10),

                            // Email or welcome back
                            storedEmployeeName == null
                                ? _EmailinputField("Email", emailController)
                                : Text(
                                  "Welcome back, $storedEmployeeName",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                            verticalSpacing(25),

                            // PIN Input
                            PasswordInputField(
                              controller: passwordController,
                              hintText: "Enter PIN",
                            ),

                            verticalSpacing(20),

                            // Role Dropdown
                            /* isRoleLocked
  ? Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        selectedRole,
        style: GoogleFonts.poppins(fontSize: 16),
      ),
    )
  : DropdownButtonFormField<String>(
  value: selectedRole,
  items: ['Employee', 'Gateman'].map((role) {
    return DropdownMenuItem<String>(
      value: role,
      child: Text(
        role,
        style: const TextStyle(color: mainColor), // Grey items
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedRole = value!;
    });
  },
  decoration: const InputDecoration(
    labelText: "LOGIN AS",
    labelStyle: TextStyle(color: Colors.grey), // Grey label
    border: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2), // Red solid border
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2), // Red when enabled
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2), // Red when focused
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  dropdownColor: Colors.white,
  iconEnabledColor: Colors.red, // Optional: red dropdown icon
),

                          verticalSpacing(22),*/

                            // Login Button
                            ActionButton(
                              onPressed: () {
                                loginUser(
                                  storedEmployeeName ??
                                      emailController.text.trim(),
                                  passwordController.text.trim(),
                                  "", // Since role is now auto-determined, you can ignore this argument or remove it
                                  //selectedRole,
                                );
                              },
                              actionText: "Login",
                            ),

                            verticalSpacing(15),
                            _buildTermsAndConditions(),

                            // Forgot PIN
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Forgot PIN? ',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF8696BB),
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Reset Here',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => ChangePin(),
                                                ),
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            verticalSpacing(15),

                            // Sign Up (if user not stored)
                            storedEmployeeName == null
                                ? Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Don’t have an account? ',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF8696BB),
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'SignUp',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            LocationAccess(),
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                )
                                : Container(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _EmailinputField(String label, TextEditingController controller) {
    return CustomTextFormField(
      controller: controller,
      hintText: "Enter Email",
      label: label,
      isBoldLabel: false,
      hasLable: false,
      hasInputBorder: true,
      hasBorderSide: true,
      hasUnderlineBorder: true,
      hasPrefixIcon: false,
      prefixIconUrl: Icons.email,
      inputType: TextInputType.emailAddress,
      inputAction: TextInputAction.next,
      fillColor: filledColor,
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          activeColor: mainColor,
          value: termsAccepted,
          onChanged: (value) {
            /*setState(() {
            termsAccepted = value ?? false;
          });*/
          },
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: const Color(0xFF8696BB),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              children: <TextSpan>[
                TextSpan(text: "I agree with "),
                TextSpan(
                  text: "privacy policy",
                  style: TextStyle(
                    color: Colors.white, // Link color
                    //decoration: TextDecoration.underline, // Underline to show it's a link
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          // Open the URL
                          launch(
                            'https://checkinproprivacy.netlify.app/',
                          ); // Use your actual URL
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
