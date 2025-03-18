import 'dart:async';
import 'dart:math';  // Import for random OTP generation
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/utils/dimensions.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

class OtpVerification extends StatefulWidget {
  const OtpVerification({super.key});

  @override
  _OtpVerificationState createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();

  bool loading = false;
  Timer? _timer;
  int _start = 60; // Countdown starts from 60 seconds
  String? _generatedOtp;

  Future<void> saveOTPCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completedOTP', true);
  }

  Future<void> generateAndSendOtp() async {
  Random random = Random();
  int otp = random.nextInt(9000) + 1000; // Generate a 4-digit OTP
  String generatedOtp = otp.toString();

  // Save OTP in SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Retrieve stored email
  String? email = prefs.getString('email') ?? "N/A";
  await prefs.setString('otp', generatedOtp);

  // SMTP Server Configuration (Use your own SMTP settings)
  String username = 'nardconcepts1@gmail.com'; // Your email
  String password = 'hona yzax gkyc rwei'; // Your email app password (use App Passwords for security)
  
  final smtpServer = gmail(username, password); // Use Gmail's SMTP server
  
  // Email Message
  final message = Message()
    ..from = Address(username, 'Safebusiness') // Sender info
    ..recipients.add(email) // Recipient email
    ..subject = 'Your OTP Code for Safebusiness'
    ..text = 'Your OTP code is: $generatedOtp\nPlease enter this code in the app to proceed.';

  try {
    final sendReport = await send(message, smtpServer);
    print('OTP sent successfully: ${sendReport.toString()}');
  } catch (e) {
    print('Failed to send OTP: $e');
  }
}

  @override
  void initState() {
    super.initState();
    generateAndSendOtp(); // Generate and save OTP when the screen is initialized
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start > 0) {
        setState(() {
          _start--;
        });
      } else {
        setState(() {
          _timer?.cancel(); // Stop the timer when it reaches 0
        });
      }
    });
  }

  @override
  void dispose() {
    _fieldFour.dispose();
    _fieldThree.dispose();
    _fieldTwo.dispose();
    _fieldOne.dispose();
    _timer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  Future<void> verifyOtp() async {
    // Get the OTP from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedOtp = prefs.getString('otp');

    // Compare the entered OTP with the saved one
    String enteredOtp = _fieldOne.text + _fieldTwo.text + _fieldThree.text + _fieldFour.text;

    if (savedOtp == enteredOtp) {
      // OTP is correct, proceed with verification
      await saveOTPCompletion();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // OTP is incorrect, show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              verticalSpacing(MediaQuery.of(context).size.height * 0.17),
              Transform.scale(
                  scale: 1.2,
                  child: Image.asset(
                    'assets/icons/safe-biz-cropped.png',
                  )),
              verticalSpacing(MediaQuery.of(context).size.height * 0.06),
              Text(
                'OTP Verification',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF0D1B34),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              verticalSpacing(35),
              Text(
                'Enter the verification code that we have just sent to your phone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF8696BB),
                  fontSize: Dimensions.FONT_SIZE_DEFAULT,
                  fontWeight: FontWeight.w400,
                ),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.05),
              // Display OTP on the screen for testing
              if (_generatedOtp != null) 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OtpInput(_fieldOne, true),
                  horizontalSpacing(10),
                  OtpInput(_fieldTwo, false),
                  horizontalSpacing(10),
                  OtpInput(_fieldThree, false),
                  horizontalSpacing(10),
                  OtpInput(_fieldFour, false),
                  horizontalSpacing(10),
                ],
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.05),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Resend OTP ',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8696BB),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: _start > 0 ? '$_start seconds' : 'Resend now',
                      style: GoogleFonts.poppins(
                        color: mainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          if (_start == 0) {
                            // Resend OTP logic
                            generateAndSendOtp(); // Generate new OTP
                            setState(() {
                              _start = 60; // Reset timer
                            });
                            _startTimer(); // Start the timer again
                          }
                        },
                    ),
                  ],
                ),
              ),
              verticalSpacing(MediaQuery.of(context).size.height * 0.02),
              ActionButton(
                onPressed: () async {
                  await verifyOtp(); // Verify OTP on button press
                },
                actionText: 'Verify',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Create an input widget that takes only one digit
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  const OtpInput(this.controller, this.autoFocus, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 58,
        width: 58,
        child: TextField(
          autofocus: autoFocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          controller: controller,
          maxLength: 1,
          cursorColor: black,
          decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderSideColor),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderSideColor),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: mainColor.withOpacity(0.2)),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              counterText: '',
              hintStyle: const TextStyle(color: black, fontSize: 20.0)),
          onChanged: (value) {
            if (value.length == 1) {
              FocusScope.of(context).nextFocus();
            }
          },
        ),
      ),
    );
  }
}