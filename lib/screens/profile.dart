import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/change_pin.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/custom_divider.dart';
import 'package:safebusiness/widgets/sized_box.dart';
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
    //final themeChange = Provider.of<DarkThemeProvider>(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpacing(25),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Profile"),
              ),
              verticalSpacing(10.0),
              customDivider(
                thickness: 3,
                indent: 0,
                endIndent: 0,
                color: const Color(0xFFD9D9D9),
              ),
              verticalSpacing(15),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 20),
                child: Row(
                  children: [
                /*    const CircleAvatar(
                    radius: 38,
                    backgroundColor: lightGrey,
                    child: Icon(
                      Icons.person,
                      color: darkgrey,
                      size: 50,
                    ),
                  ),*/
                    horizontalSpacing(30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headerTextBold(employeeName),
                        _headerText(email),
                        verticalSpacing(5.0),
                        Container(
                          width: 81,
                          height: 18,
                          decoration: ShapeDecoration(
                            color: const Color(0x89F70101),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verified',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              horizontalSpacing(4),
                              Container(
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: mainColor,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpacing(15),
              customDivider(
                thickness: 2,
                indent: 40,
                endIndent: 40,
                color: const Color(0xFF8696BB),
              ),
              verticalSpacing(15),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 20),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40, right: 20),
                        child: InkWell(
                          onTap: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            // Navigate to the LoginPage when the Logout button is tapped
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Container(
                            width: 92,
                            height: 29,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF70101),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(60),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      horizontalSpacing(20),
                      const VerticalDivider(
                        color: Color(0xFF8696BB),
                        thickness: 1,
                      ),
                      const Icon(
                        Icons.star,
                        size: 19,
                        color: Color(0xFFEDE300),
                      ),
                      horizontalSpacing(5.0),
                      Text(
                        '4.0 (22 Reviews)',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8696BB),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              verticalSpacing(30),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Company Name"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(companyName),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Company Email"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(companyEmail),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Branch"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(branchName),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Department"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(departmentName),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Designation"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(designationName),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Employee ID"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(employeeId),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Phone Number"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(phone),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerTextBold("Address"),
              ),
              verticalSpacing(5.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _headerText(address),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20, right: 25),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChangePin(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.refresh_outlined,
                          color: mainColor,
                        ),
                      ),
                      Text(
                        'Update Pin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF70101),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
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

  Widget _headerText(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF8696BB),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
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
}
