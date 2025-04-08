import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/Auth/location_access.dart';
import 'package:safebusiness/screens/change_pin.dart';
import 'package:safebusiness/screens/password_input.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/custom_text_form_field.dart';
import '../../widgets/btm_nav_bar.dart';
import '../../widgets/sized_box.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedEmployeeName = prefs.getString('employeeName'); // Get stored name
      storedEmployeeId = prefs.getString('employeeid');
    });
  }

  Future<void> loginUser(String email, String password) async {
  try {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/loginUser");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEmail = prefs.getString('email'); // Retrieve stored email

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "username": storedEmail ?? email, // Use stored email if available
        "password": password.trim(),
      }),
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
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
          await prefs.setString('companyEmail', data['companyEmail'] ?? "N/A");
          await prefs.setInt('branchId', data['branch_id'] ?? 0);
          await prefs.setInt('departmentId', data['department_id'] ?? 0);
          await prefs.setInt('designationId', data['designation_id'] ?? 0);
        }


        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
        print("Login successful.");
      } else {
        _showError("Invalid email or PIN");
      }
    } else {
      _showError("Failed to login: ${response.statusCode}");
    }
  } catch (e) {
    _showError("Error logging in: $e");
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
        backgroundColor: Colors.white,
        body: Column(
          children: [
            verticalSpacing(MediaQuery.of(context).size.height * 0.10),
            Transform.scale(scale: 0.5, child: Image.asset('assets/icons/checkin.png')),
            verticalSpacing(MediaQuery.of(context).size.height * 0.06),
            Text(
              'Login',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0D1B34),
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
                          
                          // Show Employee Name if already stored, otherwise show email input
                          storedEmployeeName == null
                              ? _EmailinputField("Email", emailController)
                              : Text(
                                  "Welcome back, $storedEmployeeName",
                                  style: GoogleFonts.poppins(
                                    color: mainColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                          verticalSpacing(25),
                          PasswordInputField(controller: passwordController, hintText: "Enter PIN"),
                          verticalSpacing(22),
                          ActionButton(
                            onPressed: () {
                              loginUser(
                                storedEmployeeName ?? emailController.text.trim(),
                                passwordController.text.trim(),
                              );
                            },
                            actionText: "Login",
                          ),
                          verticalSpacing(15),
                          _buildTermsAndConditions(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Forgot PIN? ',
                                    style: GoogleFonts.poppins(color: const Color(0xFF8696BB), fontSize: 14),
                                  ),
                                  TextSpan(
                                    text: 'Reset Here',
                                    style: GoogleFonts.poppins(color: mainColor, fontSize: 14),
                                    recognizer: TapGestureRecognizer()..onTap = () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePin()));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          verticalSpacing(15),
                          storedEmployeeName == null
                              ? Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Don’t have an account? ',
                                        style: GoogleFonts.poppins(color: const Color(0xFF8696BB), fontSize: 14),
                                      ),
                                      TextSpan(
                                        text: 'SignUp',
                                        style: GoogleFonts.poppins(color: mainColor, fontSize: 14),
                                        recognizer: TapGestureRecognizer()..onTap = () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => LocationAccess()));
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : Container(), // Hide signup option if user already exists
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
                  color: mainColor, // Link color
                  //decoration: TextDecoration.underline, // Underline to show it's a link
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // Open the URL
                    launch('https://nardconcepts.io/checkinpro-privacy-policy/'); // Use your actual URL
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
