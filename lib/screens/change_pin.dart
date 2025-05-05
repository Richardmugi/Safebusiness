import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/helpers/custom_text_form_field.dart';
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/color_resources.dart';
import '../widgets/custom_divider.dart';
import '../widgets/sized_box.dart';

class ChangePin extends StatefulWidget {
  const ChangePin({super.key});

  @override
  State<ChangePin> createState() => _ChangePinState();
}

class _ChangePinState extends State<ChangePin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();


  // Reset textfield controllers
  final TextEditingController _fieldOne1 = TextEditingController();
  final TextEditingController _fieldTwo1 = TextEditingController();
  final TextEditingController _fieldThree1 = TextEditingController();
  final TextEditingController _fieldFour1 = TextEditingController();
  String _userEmail = '';


  @override
void initState() {
  super.initState();
  _loadUserDetails();
}

Future<void> _loadUserDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString("email") ?? "N/A";
  setState(() {
    _userEmail = email;
    _emailController.text = email; // Set the controller's value
  });
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
              verticalSpacing(25),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon:
                          const Icon(Icons.arrow_back_ios_outlined, size: 20)),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: _headerTextBold('Change your Pin'),
                  ),
                ],
              ),
              verticalSpacing(5.0),
              customDivider(
                  thickness: 3,
                  indent: 0,
                  endIndent: 0,
                  color: const Color(0xFFD9D9D9)),
              verticalSpacing(15),
              // MESSAGE
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: _headerText('You can change your PIN here'),
              ),
              verticalSpacing(15),
             /* Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 10),
                child: Text('Enter Username/Email',
                    style: GoogleFonts.poppins(
                      color: mainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    )),
              ),*/
              verticalSpacing(15),
              TextFormField(
  controller: _emailController, // ✅ Reactive
  readOnly: true,
  decoration: InputDecoration(
    labelText: "Email",
    border: OutlineInputBorder(),
    filled: true,
    fillColor: filledColor,
  ),
  style: TextStyle(color: Colors.grey[700]),
),

              verticalSpacing(25),
              // ENTER OLD PIN
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 10),
                child: Text('Enter Old PIN',
                    style: GoogleFonts.poppins(
                      color: mainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    )),
              ),
              verticalSpacing(15),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      OtpInput(_fieldOne, true),
      horizontalSpacing(10), // auto focus
      OtpInput(_fieldTwo, false),
      horizontalSpacing(10),
      OtpInput(_fieldThree, false),
      horizontalSpacing(10),
      OtpInput(_fieldFour, false),
      horizontalSpacing(10),
    ],
  ),
)

              ),
              // ENTER NEW PIN
              verticalSpacing(25),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 10),
                child: Text('Enter New PIN',
                    style: GoogleFonts.poppins(
                      color: mainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    )),
              ),
              verticalSpacing(10),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    OtpInput(_fieldOne1, true),
                    horizontalSpacing(10), // auto focus
                    OtpInput(_fieldTwo1, false),
                    horizontalSpacing(10),
                    OtpInput(_fieldThree1, false),
                    horizontalSpacing(10),
                    OtpInput(_fieldFour1, false),
                    horizontalSpacing(10),
                  ],
                ),
              ),
              verticalSpacing(20),
Align(
                alignment: Alignment.center,
                child: ActionButton(
                  onPressed: _changePassword,
                  actionText: 'Update PIN',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*Widget _EmailinputField(String label, TextEditingController controller) {
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
  }*/

  Future<void> _changePassword() async {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/changePassword");
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _userEmail, // Use the username/email from the input
        "oldPassword": "${_fieldOne.text}${_fieldTwo.text}${_fieldThree.text}${_fieldFour.text}",
        "newPassword": "${_fieldOne1.text}${_fieldTwo1.text}${_fieldThree1.text}${_fieldFour1.text}"

      }),
    );

    var responseData = jsonDecode(response.body);
    if (responseData["status"] == "SUCCESS") { // Ensure the status key matches the API response
      // Handle success response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully!')),
      );
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ));
    } else {
      // Handle error response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData["message"] ?? 'Error changing password')),
      );
    }
  }


  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _headerText(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.black.withOpacity(0.6000000238418579),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  const OtpInput(this.controller, this.autoFocus, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: SizedBox(
        height: 58,
        width: 45,
        child: TextField(
          autofocus: autoFocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          controller: controller,
          maxLength: 1,
          cursorColor: black,
          decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE4E4E4),
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
