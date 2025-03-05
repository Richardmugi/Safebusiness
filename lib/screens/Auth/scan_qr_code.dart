import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/screens/QRCodeScanner.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanQRCode extends StatelessWidget {
  const ScanQRCode({super.key});


  Future<void> saveScanQRCompletion() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('completedScanQR', true);
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            verticalSpacing(MediaQuery.of(context).size.height * 0.1),
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height * 0.16,
              decoration: ShapeDecoration(
                color: const Color(0x60D9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scan QR Code',
                    style: GoogleFonts.poppins(
                      color: black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  verticalSpacing(5),
                  Text(
                    'Scan QR Code to Register',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: textGreyColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            verticalSpacing(MediaQuery.of(context).size.height * 0.09),
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Image.asset('assets/icons/Vector.png'),
                    ),
                    Positioned(
                      top: 0,
                      right: 15,
                      bottom: 15,
                      left: 5,
                      child: Transform.scale(
                          scale: 0.8,
                          child: Image.asset('assets/icons/qr-code.png')),
                    ),
                  ],
                ),
              ),
            ),
            verticalSpacing(MediaQuery.of(context).size.height * 0.18),
            ActionButton(
              onPressed: () async {
                await saveScanQRCompletion();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QRCodeScanner())); // Navigate to QRCodeScanner
              },
              actionText: 'Click Here to Scan',
            ),
          ],
        ),
      ),
    );
  }
}