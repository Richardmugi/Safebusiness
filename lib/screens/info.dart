import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class UserInfoFormPage extends StatefulWidget {
  const UserInfoFormPage({super.key});

  @override
  State<UserInfoFormPage> createState() => _UserInfoFormPageState();
}

class _UserInfoFormPageState extends State<UserInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isNameEditable = false;
  bool _isContactEditable = false;
  bool _isAddressEditable = false;


  @override
  void initState() {
  super.initState();
  _loadUserDataFromPrefs();
}

Future<void> _loadUserDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    _nameController.text = prefs.getString('employeeName') ?? '';
    _contactController.text = prefs.getString('phone') ?? '';
    _addressController.text = prefs.getString('address') ?? '';
  });
}

  Future<void> sendSms(String adminPhone, String clientPhone, String name, String contact, String address) async {
  const smsApiUrl = 'http://65.21.59.117:8003/v1/notification/sms';

  // Message to admin
  final adminMessage = '''
Hello NC, this client has placed an order through Checkinpro.
Name: $name
Contact: $contact
Address: $address
Please reach out to them.
''';

  // Message to client
  final clientMessage = '''
Hello $name, your order has been received successfully through Checkinpro.
You will be contacted shortly. Thank you!
''';

  try {
    // Send to admin
    final adminResponse = await http.post(
      Uri.parse(smsApiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phoneNumber": adminPhone,
        "message": adminMessage,
        "vendor": "Ego",
      }),
    );

    if (adminResponse.statusCode == 200) {
      print("Admin SMS sent successfully");
    } else {
      print("Failed to send admin SMS: ${adminResponse.body}");
    }

    // Send to client
    final clientResponse = await http.post(
      Uri.parse(smsApiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phoneNumber": clientPhone,
        "message": clientMessage,
        "vendor": "Ego",
      }),
    );

    if (clientResponse.statusCode == 200) {
      print("Client SMS sent successfully");
    } else {
      print("Failed to send client SMS: ${clientResponse.body}");
    }
  } catch (e) {
    print("Error sending SMS: $e");
  }
}



  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();

    print('Name: $name');
    print('Contact: $contact');
    print('Address: $address');

    // Example: send SMS to NC (admin/manager)
    const adminPhone = "+256781794950";
    var clientPhone = contact; // Replace with valid test number
    await sendSms(adminPhone, clientPhone, name, contact, address);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your information has been sent. You will receive confirmation shortly!'), backgroundColor: mainColor,),
    );

    _formKey.currentState!.reset();
    _nameController.clear();
    _contactController.clear();
    _addressController.clear();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_outlined, size: 20, color: mainColor),
        ),
        title: Text(
          'Your Information',
          style: GoogleFonts.poppins(
            color: mainColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        /*decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4B0000), // Deep Burgundy
              Color(0xFFF80101), // Dark Red
              Color(0xFF8B0000),
            ],
          ),
        ),*/
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your details',
                style: GoogleFonts.poppins(
                  color: mainColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need this information to process your order',
                style: GoogleFonts.poppins(
                  color: mainColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              Form(
  key: _formKey,
  child: Column(
    children: [
      _buildTextField(
        controller: _nameController,
        label: 'Full Name',
        hint: 'Enter your full name',
        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
        isEditable: _isNameEditable,
        onEditTap: () {
          setState(() => _isNameEditable = true);
        },
      ),
      const SizedBox(height: 20),

      _buildTextField(
        controller: _contactController,
        label: 'Contact Number',
        hint: 'Enter your phone number',
        keyboardType: TextInputType.phone,
        validator: (value) => value == null || value.isEmpty ? 'Enter a valid contact' : null,
        isEditable: _isContactEditable,
        onEditTap: () {
          setState(() => _isContactEditable = true);
        },
      ),
      const SizedBox(height: 20),

      _buildTextField(
        controller: _addressController,
        label: 'Address',
        hint: 'Enter your complete address',
        maxLines: 3,
        validator: (value) => value == null || value.isEmpty ? 'Please enter your address' : null,
        isEditable: _isAddressEditable,
        onEditTap: () {
          setState(() => _isAddressEditable = true);
        },
      ),
      const SizedBox(height: 40),

      ActionButton(
        onPressed: _submitForm,
        actionText: "Submit",
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

  Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  required bool isEditable,
  required VoidCallback onEditTap,
}) {
  return Stack(
    alignment: Alignment.centerRight,
    children: [
      TextFormField(
        controller: controller,
        readOnly: !isEditable,
        style: GoogleFonts.poppins(color: mainColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: mainColor,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: mainColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: mainColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: mainColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: mainColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        cursorColor: mainColor,
      ),
      IconButton(
        icon: Icon(Icons.edit, color: mainColor, size: 20),
        onPressed: onEditTap,
      ),
    ],
  );
}
}