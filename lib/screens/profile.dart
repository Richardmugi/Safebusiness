import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/change_pin.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _SettingsState();
}

class _SettingsState extends State<Profile> {
  String employeeName = "";
  String phone = "";
  String employeeId = "";
  String email = "";
  String address = "";
  String companyEmail = "";
  String branchName = "";
  String departmentName = "";
  String designationName = "";
  String companyName = "";



  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  
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

  Future<void> _loadUserDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance(); 

  String name = prefs.getString("employeeName") ?? "N/A";
  String userPhone = prefs.getString("phone") ?? "N/A";
  String id = prefs.getString("employeeId") ?? "N/A";
  String userEmail = prefs.getString("email") ?? "N/A";
  String userAddress = prefs.getString("address") ?? "N/A";
  String userCompany = prefs.getString("companyName") ?? "N/A";
  String userCompanyEmail = prefs.getString("companyEmail") ?? "N/A";

  int branchId = prefs.getInt("branchId") ?? 0;
  int departmentId = prefs.getInt("departmentId") ?? 0;
  int designationId = prefs.getInt("designationId") ?? 0;

  setState(() {
    employeeName = name;
    phone = userPhone;
    employeeId = id;
    email = userEmail;
    address = userAddress;
    companyName = userCompany;
    companyEmail = userCompanyEmail;
  });

  // Fetch names asynchronously after UI update
  _fetchBranchName(branchId);
  _fetchDepartmentName(branchId, departmentId);
  _fetchDesignationName(departmentId, designationId);
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
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
                  _buildInfoCard(
                    title: 'Company Details',
                    items: {
                      'Company Name': companyName,
                      'Company Email': companyEmail,
                      'Branch': branchName,
                      'Department': departmentName,
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Personal Details',
                    items: {
                      'Designation': designationName,
                      'Employee ID': employeeId,
                      'Phone Number': phone,
                      'Address': address,
                    },
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    label: 'Change PIN',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePin()),
                    ),
                  ),
                  _buildActionButton(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: mainColor,
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

Widget _buildInfoCard({required String title, required Map<String, String> items}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 8,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: mainColor,
          ),
        ),
        const Divider(height: 24),
        ...items.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  Color color = mainColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
