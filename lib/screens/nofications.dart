import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_divider.dart';
import '../widgets/sized_box.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _addMorningMessage(); // Add automatic morning message
    _clearNewNotificationFlag();
  }

  Future<void> _loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = prefs.getStringList('notifications') ?? [];
    });
  }

  Future<void> _addMorningMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existingMessages = prefs.getStringList('notifications') ?? [];
    
    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);
    String? lastMessageDate = prefs.getString('lastMorningMessageDate');

    if (now.hour >= 8 && now.hour <= 10) {
      if (lastMessageDate == todayDate) {
        return;
      }

      String morningMessage =
          "Good morning! Please check in today - ${DateFormat('hh:mm a EEE MMM d, y').format(now)}";
      
      existingMessages.insert(0, morningMessage);
      await prefs.setStringList('notifications', existingMessages);
      await prefs.setString('lastMorningMessageDate', todayDate);
      await prefs.setBool('hasNewNotification', true);

      setState(() {
        notifications = existingMessages;
      });
    }
  }

  Future<void> _clearNewNotificationFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasNewNotification', false);
  }

  Future<void> _deleteNotification(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications.removeAt(index);
    });
    await prefs.setStringList('notifications', notifications);
  }

  @override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      //backgroundColor: Colors.white,
      body: Container(
        /*decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4B0000),
              Color(0xFFF80101),
              Color(0xFF8B0000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),*/
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            verticalSpacing(25),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  color: mainColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            verticalSpacing(5.0),
            Divider(
              thickness: 2,
              color: Colors.grey,
            ),
            verticalSpacing(15),
            notifications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "No notifications yet",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return messageBody(
                          bodyText: notifications[index],
                          onDelete: () => _deleteNotification(index),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}


  Widget messageBody({required String bodyText, required VoidCallback onDelete}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 17,
                decoration: ShapeDecoration(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
              ),
              horizontalSpacing(18),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF1F1F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bodyText,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF646464),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: mainColor),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          verticalSpacing(10),
        ],
      ),
    );
  }
}
