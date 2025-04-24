import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/Auth/otp_selection.dart';
import 'package:safebusiness/screens/confirm_password.dart';
//import 'package:safebusiness/screens/Auth/otp_verification.dart';
import 'package:safebusiness/screens/password_input.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/custom_text_form_field.dart';
import '../../widgets/action_button.dart';



class Register extends StatefulWidget {
  //const Register({super.key, required String scannedData});

  static String routeName = "/create_account";

  final String scannedData;
  final Map<String, dynamic>? companyData;

  const Register({super.key, required this.scannedData, this.companyData});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}



class _CreateAccountState extends State<Register> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  String? selectedBranchId;
  String? selectedDepartmentId;
  String? selectedDesignationId;
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> designations = [];

  final _formKey = GlobalKey<FormState>();
  bool termsAccepted = false;

  Future<void> saveRegisterCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completedRegister', true);
}



 @override
void initState() {
  super.initState();
  
  // Autofill company email and name
  companyEmailController.text = widget.scannedData ?? "N/A";
  companyNameController.text = widget.companyData?['companyName'] ?? "N/A";
  
  // Fetch branches immediately if company email is available
  if (companyEmailController.text.isNotEmpty && companyEmailController.text != "N/A") {
    _fetchBranches();
  }

  employeeIdController.text = _generateEmployeeId();
}

  String _generateEmployeeId() {
  const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final random = DateTime.now().millisecondsSinceEpoch % 1000; // Ensures unique numbers
  final firstLetter = letters[DateTime.now().millisecondsSinceEpoch % letters.length];
  final secondLetter = letters[(DateTime.now().millisecondsSinceEpoch ~/ 10) % letters.length];
  return "$firstLetter$secondLetter${random.toString().padLeft(3, '0')}";
}



  Future<void> _fetchBranches() async {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyBranches");
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "companyEmail": companyEmailController.text,
      }),
    );

    var responseData = jsonDecode(response.body);
    if (responseData["status"] == "SUCCESS") {
      setState(() {
        branches = (responseData["branches"] as List)
            .map((branch) => {
                  'id': branch['id'].toString(),
                  'name': branch['name'] as String,
                })
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _fetchDepartments(String branchId) async {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyDepartmentsByBranch");
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "companyEmail": companyEmailController.text,
        "branchId": branchId,
      }),
    );

    var responseData = jsonDecode(response.body);
    if (responseData["status"] == "SUCCESS") {
      setState(() {
        departments = (responseData["departments"] as List)
            .map((dept) => {
                  'id': dept['id'].toString(),
                  'name': dept['name'] as String,
                })
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _fetchDesignations(String departmentId) async {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getDesignationsByDepartment");
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "companyEmail": companyEmailController.text,
        "departmentId": departmentId,
      }),
    );

    var responseData = jsonDecode(response.body);
    if (responseData["status"] == "SUCCESS") {
      setState(() {
        designations = (responseData["designations"] as List)
            .map((designation) => {
                  'id': designation['id'].toString(),
                  'name': designation['name'] as String,
                })
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _register() async {
    await saveRegisterCompletion();
    if (!_formKey.currentState!.validate() || !termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and accept the terms.")),
      );
      return;
    }

    print("Request Payload: ${jsonEncode({
    "email": emailController.text,
    "name": fullNameController.text,
    "password": passwordController.text,
    "companyEmail": companyEmailController.text,
    "gender": genderController.text,
    "dob": dobController.text,
    "phone": phoneController.text,
    "address": addressController.text,
    "employeeId": employeeIdController.text,
    "branch": selectedBranchId,
    "department": selectedDepartmentId,
    "designation": selectedDesignationId
  })}");

    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/registerEmployee");
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "name": fullNameController.text,
        "password": passwordController.text,
        "companyEmail": companyEmailController.text,
        "gender": genderController.text,
        "dob": dobController.text,
        "phone": phoneController.text,
        "address": addressController.text,
        "employeeId": employeeIdController.text,
        "branch": selectedBranchId,
        "department": selectedDepartmentId,
        "designation": selectedDesignationId,
      }),
    );

    var responseData = jsonDecode(response.body);
    if (responseData["status"] == "SUCCESS") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', responseData['email'] ?? "N/A");
    await prefs.setString('phone', phoneController.text);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpMethodSelection()),
      );

      print('Registered email: ${responseData['email']}');

    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            verticalSpacing(20),
            const Text(
              'Register',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            verticalSpacing(10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ListView(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Text(
      "Company Email",
      style: const TextStyle(
        fontSize: 16,
        color: Colors.red, 
        fontWeight: FontWeight.bold,
      ),
    ),
    TextFormField(
      controller: companyEmailController,
      readOnly: true, // Prevent editing
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200], // Light background for read-only field
      ),
    ),
    verticalSpacing(22),
    Text(
      "Company Name",
      style: const TextStyle(
        fontSize: 16,
        color: Colors.red, 
        fontWeight: FontWeight.bold,
      ),
    ),
    TextFormField(
      controller: companyNameController,
      readOnly: true, // Prevent editing
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200], // Light background for read-only field
      ),
    ),
                          verticalSpacing(22),
                          _NameinputField("Full Name", fullNameController),
                          verticalSpacing(22),
                          _EmailinputField("Email", emailController),
                          verticalSpacing(22),
                         PasswordInputField(controller: passwordController, hintText: 'Enter Pin',), // Use the custom password input field
                         verticalSpacing(10),
                         ConfirmPassword(controller: passwordController, hintText: 'Confirm Pin',),
                        verticalSpacing(22),
                          _GenderinputField("Gender", genderController),
                          verticalSpacing(22),
                          _AddressinputField("Address", addressController),
                          verticalSpacing(22),
                          _BirthinputField("Date of Birth", dobController),
                          verticalSpacing(22),
                          _dropdownField(
                            "Branch",
                            branches.map((b) => b['name'] as String).toList(),
                            (val) {
                              if (val != null) {
                                var selectedBranch = branches.firstWhere((b) => b['name'] == val);
                                selectedBranchId = selectedBranch['id'];
                                _fetchDepartments(selectedBranchId!);
                              }
                            },
                            hintText: "Select Branch",
                          ),
                          verticalSpacing(22),
                          _dropdownField(
                            "Department",
                            departments.map((d) => d['name'] as String).toList(),
                            (val) {
                              if (val != null) {
                                var selectedDept = departments.firstWhere((d) => d['name'] == val);
                                selectedDepartmentId = selectedDept['id'] as String;
                                _fetchDesignations(selectedDepartmentId!);
                              }
                            },
                            hintText: "Select Department",
                          ),
                          verticalSpacing(22),
                          _dropdownField(
                            "Designation",
                            designations.map((d) => d['name'] as String).toList(),
                            (val) {
                              if (val != null) {
                                var selectedDesig = designations.firstWhere((d) => d['name'] == val);
                                selectedDesignationId = selectedDesig['id'] as String;
 }
                            },
                            hintText: "Select Designation",
                          ),
                          verticalSpacing(15),
                          _PhoneinputField("Phone", phoneController),
                          verticalSpacing(22),
                          _buildTermsAndConditions(),
                          verticalSpacing(15),
                          ActionButton(
                            onPressed: _register,
                            actionText: "Register",
                          ),
                          verticalSpacing(22),
                          _buildLoginText(),
                          verticalSpacing(30),
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

  Widget _NameinputField(String s, TextEditingController fullNameController) {
    return CustomTextFormField(
      controller: fullNameController,
      hintText: "Enter Full Names",
      isBoldLabel: false,
      hasLable: false,
      hasInputBorder: true,
      hasBorderSide: true,
      hasUnderlineBorder: true,
      hasPrefixIcon: false,
      prefixIconUrl: Icons.person,
      //isValidator: true,
      //validator: Validators().validateName,
    );
  }

  Widget _EmailinputField(String s, TextEditingController emailController) {
    return CustomTextFormField(
      controller: emailController,
      hintText: "Enter Email",
      label: "Email",
      isBoldLabel: false,
      hasLable: false,
      hasInputBorder: true,
      hasBorderSide: true,
      hasUnderlineBorder: true,
      hasPrefixIcon: false,
      prefixIconUrl: Icons.email,
      inputType: TextInputType.text,
      inputAction: TextInputAction.next,
      //isValidator: true,
      fillColor: filledColor,
      //validator: Validators().validateCompanyId,
    );
  }

  

  

  Widget _GenderinputField(String label, TextEditingController genderController) {
  List<String> genderOptions = ["Male", "Female"];

  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.normal),
      filled: true,
      fillColor: filledColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    ),
    value: genderController.text.isNotEmpty ? genderController.text : null,
    hint: const Text("Select Gender"),
    items: genderOptions.map((String gender) {
      return DropdownMenuItem<String>(
        value: gender,
        child: Text(gender),
      );
    }).toList(),
    onChanged: (String? newValue) {
      genderController.text = newValue ?? "";
    },
    validator: (value) => value == null ? "$label is required" : null,
  );
}


  Widget _BirthinputField(String label, TextEditingController dobController) {
  return GestureDetector(
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900), // Ensures valid DOB
        lastDate: DateTime.now(),
      );

      String formattedDate =
          "${pickedDate?.year}-${pickedDate?.month.toString().padLeft(2, '0')}-${pickedDate?.day.toString().padLeft(2, '0')}";
      dobController.text = formattedDate;
        },
    child: AbsorbPointer(
      child: TextFormField(
        controller: dobController,
        decoration: InputDecoration(
          hintText: "YYYY-MM-DD",
          labelText: label,
          filled: true,
          fillColor: filledColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        ),
        validator: (value) => value == null || value.isEmpty
            ? "Date of Birth is required"
            : null,
      ),
    ),
  );
}


  Widget _PhoneinputField(String s, TextEditingController phoneController) {
    return CustomTextFormField(
      controller: phoneController,
      hintText: "Enter Phone Number",
      label: "Phone Number",
      isBoldLabel: false,
      hasLable: false,
      hasInputBorder: true,
      hasBorderSide: true,
      hasUnderlineBorder: true,
      hasPrefixIcon: false,
      prefixIconUrl: Icons.phone,
      inputAction: TextInputAction.next,
      inputType: TextInputType.phone,
      //isValidator: true,
      fillColor: filledColor,
      //validator: Validators().validatePhoneNumber,
    );
  }

  Widget _AddressinputField(String s, TextEditingController addressController) {
    return CustomTextFormField(
      controller: addressController,
      hintText: "Address",
      label: "Address",
      isBoldLabel: false,
      hasLable: false,
      hasInputBorder: true,
      hasBorderSide: true,
      hasUnderlineBorder: true,
      hasPrefixIcon: false,
      prefixIconUrl: Icons.lock,
      suffixIconUrl: Icons.visibility,
      hasSuffixIcon: true,
      //isPin: true,
      //inputAction: TextInputAction.next,
      //isValidator: true,
      fillColor: filledColor,
      //validator: isPinValid,
    );
  }


  Widget _dropdownField(
  String label,
  List<String> items,
  ValueChanged<String?> onChanged, {
  String? hintText,
  Color filledColor = Colors.white,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.normal), // isBoldLabel: false
        filled: true, 
        fillColor: filledColor, // fillColor property
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // hasInputBorder
          borderSide: const BorderSide(color: Colors.grey, width: 2), // hasBorderSide
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? "$label is required" : null,
    ),
  );
}


  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          activeColor: mainColor,
          value: termsAccepted,
          onChanged: (value) {
            setState(() {
              termsAccepted = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text(
            "I agree with the Terms of Service",
            style: GoogleFonts.poppins(
              color: const Color(0xFF8696BB),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginText() {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already Registered? ',
              style: GoogleFonts.poppins(
                color: textGreyColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Login Here',
              style: GoogleFonts.poppins(
                color: mainColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

}