import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/screens/announcements.dart';
import 'package:safebusiness/screens/jobs.dart';
import 'package:safebusiness/screens/leave.dart';
import 'package:safebusiness/utils/color_resources.dart';

class QuickActionsPage extends StatelessWidget {
  const QuickActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        //backgroundColor: Colors.white,
        body: SingleChildScrollView( // Make the body scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpacing(25),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    color: mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              verticalSpacing(5.0),
              customDivider(thickness: 3, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    buildActionContainer(
                      label: 'Announcements',
                      icon: Icons.notifications,
                      description: 'Check your announcements here',
                      color: Colors.blueAccent,
                      context: context, imagePath: 'assets/images/announcemnt.jpg',
                    ),
                    verticalSpacing(20.0),
                    buildActionContainer(
                      label: 'Jobs',
                      icon: Icons.work_outline,
                      description: 'Access company vacancies here',
                      color: Colors.green,
                      context: context, imagePath: 'assets/images/job.webp',
                    ),
                    verticalSpacing(20.0),
                    buildActionContainer(
                      label: 'Leave',
                      icon: Icons.attach_money,
                      description: 'Apply for leave easily',
                      color: Colors.orangeAccent,
                      context: context, imagePath: 'assets/images/leave.jpg',
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

  Widget buildActionContainer({
  required String label,
  required IconData icon,
  required String description,
  required Color color,
  required BuildContext context,
  required String imagePath, // 👈 New parameter
}) {
  return Container(
    width: MediaQuery.of(context).size.width - 24,
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(imagePath), // 👈 Use the passed image path
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.85), // Optional: soft overlay
          BlendMode.lighten,
        ),
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: mainColor),
        verticalSpacing(10.0),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: mainColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpacing(5.0),
        Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        verticalSpacing(10.0),
        ElevatedButton(
          onPressed: () {
            if (label == 'Jobs') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyJobsPage()),
              );
            } else if (label == 'Announcements') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnnouncementsPage()),
              );
            } else if (label == 'Leave') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaveApplicationPage()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: mainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Open',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

  Widget verticalSpacing(double height) {
    return SizedBox(height: height);
  }

  Widget customDivider({required double thickness, required Color color}) {
    return Container(
      height: thickness,
      color: color,
      margin: EdgeInsets.symmetric(horizontal: 24),
    );
  }
}