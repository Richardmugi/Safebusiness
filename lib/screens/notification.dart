import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/announcements.dart';
import 'package:safebusiness/screens/jobs.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  final BuildContext context;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  String companyEmail = "";
  int branchId = 0;
  String branchName = "";

  NotificationService(this.context);

  Future<void> init() async {
    await _loadUserDetails();
    await _fetchJobs();
    await _fetchAnnouncements();
  }


Future<void> showPersistentTopAlert({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onViewPressed,
}) async {
  // Play notification sound
  if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 500);
        }
        _ringtonePlayer.playNotification();

  // Show custom dialog aligned to top
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Alert",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainColor)),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dismiss alert
                    onViewPressed(); // navigate
                  },
                  child: const Text("View"),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, -1), end: Offset.zero).animate(anim),
        child: child,
      );
    },
  );
}


  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    companyEmail = prefs.getString("companyEmail") ?? "";
    branchId = prefs.getInt("branchId") ?? 0;
    await _fetchBranchName();
  }

  Future<void> _fetchBranchName() async {
    var url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyBranches");
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
        branchName = branch != null ? branch["name"] : "Unknown Branch";
      }
    }
  }

  Future<void> _fetchJobs() async {
    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyJobsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedJobs");

    var body = jsonEncode(
      branchId > 0
          ? {"companyEmail": companyEmail, "branchId": branchId}
          : {"companyEmail": companyEmail},
    );

    try {
      var response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS" && data["postedJobs"] is List) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int previousCount = prefs.getInt("jobCount") ?? 0;
          List jobs = data["postedJobs"];
          if (jobs.length > previousCount) {
            await showPersistentTopAlert(
  context: context,
  title: "New Job Alert",
  message: "${jobs.length - previousCount} new announcement(s).",
  onViewPressed: () {
    Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => CompanyJobsPage(),
                                              ),
                                            );
  },
);
            prefs.setInt("jobCount", jobs.length);
          }
        }
      }
    } catch (e) {
      print("Job fetch failed: $e");
    }
  }

  Future<void> _fetchAnnouncements() async {
    var url = branchId > 0
        ? Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyAnnouncementsByBranch")
        : Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getCompanyPostedAnnouncements");

    var body = jsonEncode(
      branchId > 0
          ? {"companyEmail": companyEmail, "branchId": branchId}
          : {"companyEmail": companyEmail},
    );

    try {
      var response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "SUCCESS" && data["announcements"] is List) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int previousCount = prefs.getInt("announcementCount") ?? 0;
          List announcements = data["announcements"];
          if (announcements.length > previousCount) {
            await showPersistentTopAlert(
  context: context,
  title: "New Announcements Alert",
  message: "${announcements.length - previousCount} new announcement(s).",
  onViewPressed: () {
    Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => AnnouncementsPage(),
                                              ),
                                            );
  },
);
            prefs.setInt("announcementCount", announcements.length);
          }
        }
      }
    } catch (e) {
      print("Announcement fetch failed: $e");
    }
  }
}
