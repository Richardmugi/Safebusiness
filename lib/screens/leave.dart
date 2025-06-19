import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeaveApplicationPage extends StatefulWidget {
  @override
  _LeaveApplicationPageState createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> leaveTypes = [];
  int? selectedLeaveTypeId;
  String leaveReason = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isSubmitting = false;
  bool isLoading = true;

  String? employeeEmail;
  String? companyEmail;

  @override
  void initState() {
    super.initState();
    loadEmailsFromPrefs();
  }

  Future<void> loadEmailsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    employeeEmail = prefs.getString('email');
    companyEmail = prefs.getString('companyEmail');
    print("Company email used: $companyEmail");

    if (employeeEmail == null || companyEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing employee or company email')),
      );
    } else {
      await fetchLeaveTypes();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchLeaveTypes() async {
    final url = Uri.parse(
      'http://65.21.59.117/safe-business-api/public/api/v1/getLeaveTypes',
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"companyEmail": companyEmail}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        leaveTypes = data['leaveTypes'] ?? [];
        print("Leave types API response: ${response.body}");
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch leave types')));
    }
  }

  Future<void> submitLeaveApplication() async {
    if (startDate == null || endDate == null || selectedLeaveTypeId == null)
      return;

    final url = Uri.parse(
      'http://65.21.59.117/safe-business-api/public/api/v1/leaveApplication',
    );
    final totalDays = endDate!.difference(startDate!).inDays + 1;

    final body = {
      "employeeEmail": employeeEmail,
      "companyEmail": companyEmail,
      "leaveType": selectedLeaveTypeId,
      "leaveReason": leaveReason,
      "startDate": startDate!.toIso8601String().split('T').first,
      "endDate": endDate!.toIso8601String().split('T').first,
      "totalDays": totalDays,
    };

    setState(() {
      isSubmitting = true;
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() {
      isSubmitting = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Leave application submitted')));
      _formKey.currentState?.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit leave application')),
      );
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainColor, // Dark blue app bar
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_outlined,
            size: 20,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Leave Application',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    leaveTypes.isEmpty
                        ? Center(child: Text('No leave types found'))
                        : Form(
                          key: _formKey,
                          child: ListView(
                            children: [
                              DropdownButtonFormField<int>(
  value: selectedLeaveTypeId,
  decoration: InputDecoration(
    labelText: 'Leave Type',
    labelStyle: TextStyle(
      color: mainColor, // label text color
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2), // color when focused
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
  ),
  items: leaveTypes.map<DropdownMenuItem<int>>((type) {
    return DropdownMenuItem<int>(
      value: type['id'],
      child: Text('${type['title']} (${type['days']} days)'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedLeaveTypeId = value;
    });
  },
  validator: (value) =>
      value == null ? 'Please select a leave type' : null,
),

                              SizedBox(height: 16),
                              TextFormField(
  decoration: InputDecoration(
    labelText: 'Leave Reason',
    labelStyle: TextStyle(
      color: mainColor, // Label text color
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2), // On focus
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 1.5), // On validation error
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainColor, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
  ),
  onChanged: (value) => leaveReason = value,
  validator: (value) =>
      value == null || value.isEmpty ? 'Enter a reason' : null,
),

                              SizedBox(height: 16),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: mainColor),
                                ),
                                title: Text(
                                  startDate == null
                                      ? 'Select Start Date'
                                      : 'Start Date: ${startDate!.toIso8601String().split("T")[0]}',
                                
                                style: TextStyle(
      color: mainColor, // Set your desired color
      fontSize: 14,
      fontWeight: FontWeight.w600, // Optional
    ),
  ),
                                trailing: Icon(Icons.calendar_today),
                                onTap: () => pickDate(context, true),
                              ),
                              SizedBox(height: 12),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: mainColor),
                                ),
                                title: Text(
                                  endDate == null
                                      ? 'Select End Date'
                                      : 'End Date: ${endDate!.toIso8601String().split("T")[0]}',
                                style: TextStyle(
      color: mainColor, // Set your desired color
      fontSize: 14,
      fontWeight: FontWeight.w600, // Optional
    ),
  ),
  
                                trailing: Icon(Icons.calendar_today),
                                onTap: () => pickDate(context, false),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
  width: double.infinity,
  height: 65,
  child: ElevatedButton(
    onPressed: isSubmitting
        ? null
        : () {
            if (_formKey.currentState!.validate()) {
              submitLeaveApplication();
            }
          },
    style: ElevatedButton.styleFrom(
      backgroundColor: mainColor, // Button background color
      foregroundColor: Colors.white, // Text/icon color
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text("Submit"),
  ),
),

                            ],
                          ),
                        ),
              ),
    );
  }
}
