import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safebusiness/screens/Auth/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRCodeScanner extends StatefulWidget {
  const QRCodeScanner({super.key, this.isReturningUser = false});
  final bool isReturningUser;

  @override
  State<QRCodeScanner> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  MobileScannerController cameraController = MobileScannerController();
  bool _navigated = false;

  Future<void> saveQRCodeScannerCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completedQRCodeScanner', true);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  bool isValidEmail(String input) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(input);
  }

  Future<void> fetchCompanyDetails(String email) async {
    const String apiUrl = "http://65.21.59.117/safe-business-api/public/api/v1/getCompanyDetails";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"companyEmail": email}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("Company Data: $data");

        await saveQRCodeScannerCompletion();

        if (widget.isReturningUser) {
          // For returning users, return the scanned email to the homepage
          Navigator.pop(context, email);
        } else {
          // For new users, navigate to the registration page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Register(
                scannedData: email,
                companyData: data,
              ),
            ),
          );
        }
      } else {
        throw Exception("Failed to fetch company details.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching company details: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (_navigated) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  String scannedData = barcode.rawValue!;
                  print("Scanned Data: $scannedData");

                  if (isValidEmail(scannedData)) {
                    setState(() {
                      _navigated = true;
                    });

                    await fetchCompanyDetails(scannedData);
                    break;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Invalid QR code! No company email found."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value * 250,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                  const Center(
                    child: Text(
                      'Align QR Code Here',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({bool top = false, bool left = false}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
