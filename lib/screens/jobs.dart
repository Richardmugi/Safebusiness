import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyJobsPage extends StatefulWidget {
  const CompanyJobsPage({super.key});

  @override
  State<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

class _CompanyJobsPageState extends State<CompanyJobsPage> {
  List jobs = [];
  String companyEmail = "";
  int branchId = 0;
  String branchName = "";
  bool isLoading = true;

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

  Future<void> _loadUserDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance(); 

  String userCompanyEmail = prefs.getString("companyEmail") ?? "N/A";

  int branchId = prefs.getInt("branchId") ?? 0;

  setState(() {
    companyEmail = userCompanyEmail;
  });

  // Fetch names asynchronously after UI update
  _fetchBranchName(branchId).then((_) {
    _fetchJobs();
  });
}


  Future<void> _fetchJobs() async {
  try {
    print("Fetching jobs...");

    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyJobsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedJobs");

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
          jobs = data["postedJobs"] is List ? data["postedJobs"] : []; // Correct key here
          isLoading = false;
        });
        print("Jobs loaded: ${jobs.length}");
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
    print("Fetch Jobs Error: $e");
    setState(() {
      isLoading = false;
    });
  }
}
@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      backgroundColor: mainColor, // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.amber, // Dark blue app bar
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_outlined, size: 20, color: Colors.white),
        ),
        title: Text(
          'Available Jobs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
              : jobs.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          "No jobs available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          var job = jobs[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Job Title
                                  Text(
                                    job["job_title"] ?? "No Title",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: mainColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Branch
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: mainColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        job["branch_name"] ?? "Unknown Location",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: mainColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    job["description"] != null
                                        ? _stripHtml(job["description"])
                                        : "No Description",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // End Date and Apply Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: mainColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "End Date: ",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: mainColor,
                                            ),
                                          ),
                                          Text(
                                            job["end_date"] ?? "N/A",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: mainColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          print("Apply for ${job["job_title"]}");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          backgroundColor: Colors.blue[800],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          "Apply",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    ),
  );
}
  String _stripHtml(String htmlString) {
    return RegExp(r'<[^>]*>').allMatches(htmlString).fold(
        htmlString,
        (previousValue, match) =>
            previousValue.replaceAll(match.group(0)!, '')).trim();
  }

  // Helper function to add vertical spacing
  Widget verticalSpacing(double height) {
    return SizedBox(height: height);
  }

  // Custom Divider function
  Widget customDivider(
      {double thickness = 1, double indent = 0, double endIndent = 0, Color color = Colors.black}) {
    return Divider(
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}




