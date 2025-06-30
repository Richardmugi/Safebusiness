import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/notify.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List announcements = [];
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
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyAnnouncementsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedAnnouncements");

    var body = jsonEncode(branchId > 0
        ? {"companyEmail": companyEmail, "branchId": branchId}
        : {"companyEmail": companyEmail});

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["status"] == "SUCCESS") {
        List fetched = data["announcements"] ?? [];

        // Load seen announcements from storage
        Set<String> seenIds = await _getSeenAnnouncementIds();
        Set<String> newSeenIds = {...seenIds};

        for (var announcement in fetched) {
          String id = announcement['id'].toString();
          if (!seenIds.contains(id)) {
            await _showNotification(
              announcement['title'] ?? 'New Announcement',
              announcement['message'] ?? '',
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
    print("Fetch Announcements Error: $e");
    setState(() => isLoading = false);
  }
}



@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      backgroundColor: Colors.white, // Light grey background
      appBar: AppBar(
        backgroundColor: mainColor, // Dark blue app bar
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_outlined, size: 20, color: Colors.white),
        ),
        title: Text(
          'Announcements',
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
              : announcements.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          "No announcements available",
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
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          var announcement = announcements[index];
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
                                  // Title
                                  Text(
                                    announcement["title"] ?? "No Title",
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
                                        announcement["branch_name"] ?? "Unknown Location",
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
                                    announcement["description"] != null
                                        ? _stripHtml(announcement["description"])
                                        : "No Description",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // End Date
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
                                            announcement["end_date"] ?? "N/A",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: mainColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Add more actions/icons here if needed
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




