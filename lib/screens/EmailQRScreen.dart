import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class EmailQrScreen extends StatefulWidget {
  const EmailQrScreen({super.key});

  @override
  State<EmailQrScreen> createState() => _EmailQrScreenState();
}

class _EmailQrScreenState extends State<EmailQrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "N/A";
    });
  }

  Future<void> _shareQrImage(BuildContext context) async {
  try {
    RenderRepaintBoundary? boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code is not ready yet!')),
      );
      return;
    }

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not convert QR to image')),
      );
      return;
    }

    Uint8List pngBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr_${email ?? "user"}.png');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Here is my Employee QR Code');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code image shared successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing image: $e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF4B0000),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
          ),
          title: Text(
            'Your Employee QR Code',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        backgroundColor: Colors.transparent, // Let the container handle the color
    body: Container(
  width: double.infinity,
  height: MediaQuery.of(context).size.height,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4B0000), // Deep Burgundy
        Color(0xFFF80101), // Dark Red
        Color(0xFF8B0000),
      ],
    ),
  ),
        child: email == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              QrImageView(
                                data: email!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                email!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Your Employee QR Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareQrImage(context),
                        icon: const Icon(Icons.download),
                        label: const Text("Download & Share QR Code"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      ),
    );
  }
}
