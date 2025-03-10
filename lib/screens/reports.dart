import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Report extends StatefulWidget {
  const Report({super.key});
  static const routeName = '/report';

  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
  Future<List<AttendanceReport>>? futureReports;
  String employeeEmail = "N/A"; // Default value
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeEmail = prefs.getString('email') ?? "N/A";
    });
    // Set default dates to today
    fromDate = DateTime.now();
    toDate = DateTime.now();
    futureReports = fetchAttendanceReport();
  }

  Future<List<AttendanceReport>> fetchAttendanceReport() async {
    final url = Uri.parse("http://65.21.59.117/safe-business-api/public/api/v1/getAttendanceReport");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": employeeEmail,
        "fromDate": fromDate?.toIso8601String().split('T').first,
        "toDate": toDate?.toIso8601String().split('T').first,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data); // Debugging line
      if (data['attendanceReport'] != null) {
        return (data['attendanceReport'] as List)
            .map((item) => AttendanceReport.fromJson(item))
            .toList();
      } else {
        return []; // Return an empty list if attendanceReport is null
      }
    } else {
      throw Exception("Failed to load attendance report");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isFromDate ? fromDate : toDate)) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
        futureReports = fetchAttendanceReport(); // Fetch reports after date selection
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Report',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: Text("From: ${fromDate?.toLocal().toString().split(' ')[0] ?? "Select"}"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context, false),
                  child: Text("To: ${toDate?.toLocal().toString().split(' ')[0] ?? "Select"}"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: FutureBuilder<List<AttendanceReport>>(
                  future: futureReports,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No attendance data available.'));
                    } else {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Check In')),
                            DataColumn(label: Text('Check Out')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: snapshot.data!.map((report) {
                            return DataRow(cells: [
                              DataCell(Text(report.date)),
                              DataCell(Text(report.checkIn)),
                              DataCell(Text(report.checkOut)),
                              DataCell(Text(report.status, style: TextStyle(color: _getStatusColor(report.status)))),
                            ]);
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Late Arrival':
        return Colors.orange;
      case 'On time':
      case 'Over time':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class AttendanceReport {
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;

  AttendanceReport({required this.date, required this.checkIn, required this.checkOut, required this.status});

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      date: json['date'] ?? '',
      checkIn: json['clock_in'] ?? 'N/A',
      checkOut: json['clock_out'] ?? 'N/A',
 status: json['status'] ?? 'Unknown',
    );
  }
}