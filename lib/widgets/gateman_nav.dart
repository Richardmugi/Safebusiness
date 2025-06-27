import 'package:flutter/material.dart';
import 'package:safebusiness/screens/Auth/gateman.dart';
import 'package:safebusiness/screens/company.dart';
import 'package:safebusiness/screens/nofications.dart';
import 'package:safebusiness/screens/reports.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/profile.dart';


class GatemanNavBar extends StatefulWidget {
  const GatemanNavBar({super.key});

  @override
  State<GatemanNavBar> createState() => _DefaultHomePageState();
}

class _DefaultHomePageState extends State<GatemanNavBar> {
  int _selectedIndex = 0;
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    _checkForNewNotifications();
  }

  Future<void> _checkForNewNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    print('New Notification Flag: $hasNewNotification'); // Debug log
    setState(() {
      _hasNewNotification = hasNewNotification;
    });
  }

  void _navigateBottomBar(int index) {
    if (index == 1) {
      // If navigating to the notifications page, clear the new notification flag
      _clearNewNotificationFlag();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _clearNewNotificationFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasNewNotification', false);
    setState(() {
      _hasNewNotification = false;
    });
  }

  final List<Widget> _pages = [
    Gateman(),
    const Notifications(),
    Report(),
    QuickActionsPage(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 5.0,
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/home.png'),
              size: 30,
            ),
            label: 'Home',
            backgroundColor: Color(0xff40c4ff),
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                ImageIcon(
                  AssetImage('assets/icons/notification.png'),
                  size: 30,
                ),
                if (_hasNewNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
            backgroundColor: Color(0xff40c4ff),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/chart.png'),
              size: 30,
            ),
            label: 'Reports',
            backgroundColor: Color(0xff40c4ff),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/company.png'),
              size: 30,
            ),
            label: 'My Company',
            backgroundColor: Color(0xff40c4ff),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/user-avatar.png'),
              size: 30,
            ),
            label: 'Profile',
            backgroundColor: Color(0xff40c4ff),
          ),
        ],
      ),
    );
  }
}