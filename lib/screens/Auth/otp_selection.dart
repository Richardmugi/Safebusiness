import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/screens/Auth/otp_verification.dart'; // New email OTP page
import 'package:safebusiness/screens/Auth/otp_verification_sms.dart'; // New SMS OTP page
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/sized_box.dart';

class OtpMethodSelection extends StatefulWidget {
  const OtpMethodSelection({super.key});

  @override
  _OtpMethodSelectionState createState() => _OtpMethodSelectionState();
}

class _OtpMethodSelectionState extends State<OtpMethodSelection> {
  String? _selectedMethod;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  Future<void> _loadStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMethod = prefs.getString('otpMethod') ?? 'email';
      _phoneNumber = prefs.getString('phone');
    });
  }

  Future<void> _savePreferencesAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('otpMethod', _selectedMethod!);
    
    // Navigate to different pages based on selection
    if (_selectedMethod == 'email') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpVerification()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpVerificationSms()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Verification Method',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            verticalSpacing(40),
            Text(
              'Select your preferred OTP delivery method',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0D1B34),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            verticalSpacing(30),
            
            // Email Option Card
            _buildMethodCard(
              icon: Icons.email_outlined,
              title: "Email Verification",
              subtitle: "OTP will be sent to your registered email",
              isSelected: _selectedMethod == 'email',
              onTap: () => setState(() => _selectedMethod = 'email'),
            ),
            verticalSpacing(20),
            
            // SMS Option Card
            _buildMethodCard(
              icon: Icons.sms_outlined,
              title: "SMS Verification",
              subtitle: _phoneNumber != null 
                  ? "OTP will be sent to $_phoneNumber"
                  : "Phone number not available",
              isSelected: _selectedMethod == 'sms',
              onTap: _phoneNumber != null 
                  ? () => setState(() => _selectedMethod = 'sms')
                  : null,
              isEnabled: _phoneNumber != null,
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferencesAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            verticalSpacing(30),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? mainColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainColor : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? (isSelected ? mainColor : const Color(0xFFF5F5F5))
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled 
                    ? (isSelected ? Colors.white : Colors.black54)
                    : Colors.grey,
                size: 24,
              ),
            ),
            horizontalSpacing(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isEnabled ? Colors.black : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  verticalSpacing(4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: isEnabled ? const Color(0xFF8696BB) : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: mainColor,
              ),
          ],
        ),
      ),
    );
  }
}