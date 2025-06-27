import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safebusiness/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LateCheckInNotifier {
  static Future<void> checkAndSendLateSms() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phone');

    // Ensure phone number exists
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    // Get current local time
    final now = DateTime.now();
    final localTime = now;

    // Define the check-in deadline time (10:00 AM)
    final deadline = DateTime(localTime.year, localTime.month, localTime.day, 10, 40);

    // Check if current time is after 10 AM
    if (localTime.isAfter(deadline)) {
      final isCheckedIn = await CheckInManager.isCheckedIn();  // use your existing logic

      if (!isCheckedIn) {
        final message = "Good morning! You are late for check-in. Please remember to check in as soon as possible.";

        final response = await http.post(
          Uri.parse('http://65.21.59.117:8003/v1/notification/sms'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phoneNumber": phoneNumber,
            "message": message,
            "vendor": "Ego",
          }),
        );

        if (response.statusCode == 200) {
          print("Late check-in SMS sent successfully.");
        } else {
          print("Failed to send SMS: ${response.statusCode} - ${response.body}");
        }
      }
    }
  }
}
