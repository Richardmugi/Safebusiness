import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/EmailQRScreen.dart';
import 'package:safebusiness/screens/FaceRec/Face_checkin.dart';
import 'package:safebusiness/screens/FaceRec/face_registration.dart';
import 'package:safebusiness/screens/change_pin.dart';
import 'package:safebusiness/screens/profile2.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _SettingsState();
}

class _SettingsState extends State<Profile> {
  String employeeName = "";
  String email = "";



  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  
  }


  Future<void> _loadUserDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance(); 
  String name = prefs.getString("employeeName") ?? "N/A";
  String userEmail = prefs.getString("email") ?? "N/A";
  setState(() {
    employeeName = name;
    email = userEmail;
  });
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    //backgroundColor: Color(0xFF8B0000),
    body: SafeArea(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            //color: mainColor,
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   /* Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),*/
                  ],
                ),
                const SizedBox(height: 16),
                // Profile Picture Section
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: mainColor, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: lightGrey,
                        child: Icon(
                          Icons.person,
                          color: darkgrey,
                          size: 50,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: mainColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  employeeName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Information Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Action Buttons
                  _buildActionButton(
                    icon: Icons.logout,
                    label: 'Personal Information',
                    color: Colors.white,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Profile2()),
                      );
                    },
                  ),
                  /*_buildActionButton(
                    icon: Icons.logout,
                    label: 'Register Face',
                    color: Colors.white,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaceRegisterPage()),
                      );
                    },
                  ),*/
                  /*_buildActionButton(
                    icon: Icons.logout,
                    label: 'Checkin',
                    color: Colors.white,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaceCheckInPage()),
                      );
                    },
                  ),*/
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    label: 'Change PIN',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePin()),
                    ),
                  ),
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    label: 'generate Employee QR Code',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmailQrScreen()),
                    ),
                  ),
                  _buildActionButton(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: Colors.white,
                    onTap: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
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

Widget _buildActionButton({
  required IconData icon,
  required String label,
  Color color = Colors.white,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: color, size: 20),
        ],
      ),
    ),
  );
}
}
