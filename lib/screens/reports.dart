import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safebusiness/utils/color_resources.dart';
import '../widgets/custom_divider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

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
    final url = Uri.parse(
      "http://65.21.59.117/safe-business-api/public/api/v1/getAttendanceReport",
    );
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
      initialDate:
          isFromDate
              ? (fromDate ?? DateTime.now())
              : (toDate ?? DateTime.now()),
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
        futureReports =
            fetchAttendanceReport(); // Fetch reports after date selection
      });
    }
  }

  Future<void> _downloadCSV() async {
    if (futureReports == null) return;

    List<AttendanceReport> reports = await futureReports!;

    if (reports.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No data available to download.')));
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add([
      'Date',
      'Check In',
      'Check Out',
      'Status',
      'late',
      'earlyleaving',
      'overtime',
    ]); // Header

    for (var report in reports) {
      rows.add([
        report.date,
        report.checkIn,
        report.checkOut,
        report.status,
        report.late,
        report.early_leaving,
        report.overtime,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Get the Documents directory for iOS
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/attendance_report.csv';

    // Write the file
    File file = File(path);
    await file.writeAsString(csv);

    // Share the file (works on iOS and Android)
    await Share.shareXFiles([XFile(path)], text: 'Attendance Report');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV file saved and ready to share!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              verticalSpacing(25),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Text(
                      'Attendance',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8696BB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpacing(5.0),
              customDivider(
                thickness: 3,
                indent: 0,
                endIndent: 0,
                color: const Color(0xFFD9D9D9),
              ),
              verticalSpacing(15),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check In Report',
                          style: GoogleFonts.poppins(
                            color: mainColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        verticalSpacing(10),
                        Text(
                          '${fromDate?.toLocal().toString().split(' ')[0] ?? "N/A"} to ${toDate?.toLocal().toString().split(' ')[0] ?? "N/A"}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8696BB),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _selectDate(context, true),
                              icon: Image.asset(
                                'assets/icons/magnifying-glass.png',
                                color: mainColor,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            horizontalSpacing(10),
                            IconButton(
                              onPressed: () => _downloadCSV(),
                              icon: Icon(
                                Icons.download,
                                color: mainColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        verticalSpacing(15),
                        
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpacing(40),
              FutureBuilder<List<AttendanceReport>>(
                future: futureReports,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No attendance data available.'),
                    );
                  } else {
                    return Column(
                      children:
                          snapshot.data!.map((report) {
                            return mainDataContainer(
                              context,
                              title1: report.date,
                              title2: 'Check In',
                              title3: 'Check Out',
                              title4: 'Status',
                              val1: report.date,
                              val2: report.checkIn,
                              val3: report.checkOut,
                              val4: report.status,
                              val4Color: _getStatusColor(report.status),
                            );
                          }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mainDataContainer(
  BuildContext context, {
  required String title1,
  required String title2,
  required String title3,
  required String title4,
  required String val1,
  required String val2,
  required String val3,
  required String val4,
  required Color val4Color,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    width: MediaQuery.of(context).size.width * 0.9,
    padding: const EdgeInsets.all(10),
    decoration: ShapeDecoration(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      shadows: const [
        BoxShadow(
          color: Color(0x11000000),
          blurRadius: 8,
          offset: Offset(0, 0),
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title1),
              verticalSpacing(2),
              _headerText(val1),
            ],
          ),
        ),
        horizontalSpacing(MediaQuery.of(context).size.width * 0.02),
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title2),
              verticalSpacing(2),
              _headerText(val2),
            ],
          ),
        ),
        horizontalSpacing(MediaQuery.of(context).size.width * 0.02),
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title3),
              verticalSpacing(2),
              _headerText(val3),
            ],
          ),
        ),
        horizontalSpacing(MediaQuery.of(context).size.width * 0.02),
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title4),
              verticalSpacing(2),
              _headerText(val4, color: val4Color),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget verticalSpacing(double height) {
  return SizedBox(height: height);
}

Widget horizontalSpacing(double width) {
  return SizedBox(width: width);
}

  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF8696BB),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _headerText(String title, {Color color = const Color.fromARGB(255, 28, 32, 43)}) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Late Arrival':
        return const Color(0xFFFF8D05);
      case 'On time':
      case 'Over time':
        return const Color(0xFF389916);
      default:
        return mainColor;
    }
  }
}

class AttendanceReport {
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;
  final String late;
  final String early_leaving;
  final String overtime;

  AttendanceReport({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.late,
    required this.early_leaving,
    required this.overtime,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      date: json['date'] ?? '',
      checkIn: json['clock_in'] ?? 'N/A',
      checkOut: json['clock_out'] ?? 'N/A',
      status: json['status'] ?? 'Unknown',
      late: json['late'] ?? 'N/A',
      early_leaving: json['earlyleaving'] ?? 'N/A',
      overtime: json['overtime'] ?? 'N/A',
    );
  }
}
