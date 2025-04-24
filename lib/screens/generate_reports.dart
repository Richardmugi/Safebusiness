/*import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/widgets/action_button.dart';
import 'package:safebusiness/widgets/sized_box.dart';
import 'package:intl/intl.dart';

import '../helpers/route_helper.dart';
import '../widgets/custom_divider.dart';

class GenerateReport extends StatefulWidget {
  const GenerateReport({super.key});

  @override
  State<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends State<GenerateReport> {
  int selectedIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;

  void onBoxTapped(int index) {
    setState(() {
      if (selectedIndex == index) {
      selectedIndex = -1; // Deselect if already selected
    } else {
      selectedIndex = index; // Select the tapped checkbox
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpacing(25),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: _headerTextBold("Reports")),
              ),
              verticalSpacing(10.0),
              customDivider(
                  thickness: 3,
                  indent: 0,
                  endIndent: 0,
                  color: const Color(0xFFD9D9D9)),
              verticalSpacing(15),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.14,
                padding: const EdgeInsets.only(left: 22, right: 22, top: 18),
                margin: const EdgeInsets.only(left: 24, right: 24),
                decoration: ShapeDecoration(
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary this Month',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _upperSummaryWidget('21', 'Present'),
                        _upperSummaryWidget('5', 'Late'),
                        _upperSummaryWidget('1', 'Absent'),
                        _upperSummaryWidget('27', 'Check Ins'),
                      ],
                    )
                  ],
                ),
              ),
              //CALENDAR DATE PICKER
              verticalSpacing(20),
             
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: EasyDateTimeLine(
                  initialDate: DateTime.now(),
                  onDateChange: (selectedDate) {
                    //`selectedDate` the new date selected.
                  },
                  activeColor: mainColor,
                  headerProps: const EasyHeaderProps(
                    monthPickerType: MonthPickerType.switcher,
                    //selectedDateFormat: SelectedDateFormat.fullDateDayAsStrMY,
                  ),
                  dayProps: const EasyDayProps(
                    activeDayStyle: DayStyle(
                      borderRadius: 8.0,
                    ),
                    inactiveDayStyle: DayStyle(
                      borderRadius: 8.0,
                    ),
                  ),
                  timeLineProps: const EasyTimeLineProps(
                    hPadding: 16.0, // padding from left and right
                    separatorPadding: 16.0, // padding between days
                  ),
                ),
              ),

              // STARTING DATE AND ENDING DATE
              verticalSpacing(20),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _datePickerWidget(context, "Starting", _startDate, (date) {
                      setState(() {
                        _startDate = date;
                      });
                    }),
                    _datePickerWidget(context, "Ending", _endDate, (date) {
                      setState(() {
                        _endDate = date;
                      });
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: _headerTextBold("Employee Status")),
              ),
              verticalSpacing(5),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: _headerText("Select employee status")),
              ),
              verticalSpacing(20),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _checkBoxesWidget(
                      context,
                      onTap: () {
                        onBoxTapped(0);
                      },
                      borderColor: selectedIndex == -1
                          ? mainColor
                          : const Color(0xFFC4C4C4),
                      label: 'Check In',
                      isSelected: selectedIndex == -1,
                      
                    ),
                    _checkBoxesWidget(
                      context,
                      onTap: () {
                        onBoxTapped(1);
                      },
                      borderColor: selectedIndex == 1
                          ? mainColor
                          : const Color(0xFFC4C4C4),
                      label: 'Check Out',
                      isSelected: selectedIndex == 1,
                    ),
                  ],
                ),
              ),
              verticalSpacing(20),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _checkBoxesWidget(
                      context,
                      onTap: () {
                        onBoxTapped(2);
                      },
                      borderColor: selectedIndex == 2
                          ? mainColor
                          : const Color(0xFFC4C4C4),
                      label: 'Absent',
                      isSelected: selectedIndex == 2,
                    ),
                    _checkBoxesWidget(
                      context,
                      onTap: () {
                        onBoxTapped(3);
                      },
                      borderColor: selectedIndex == 3
                          ? mainColor
                          : const Color(0xFFC4C4C4),
                      label: 'Late Arrival',
                      isSelected: selectedIndex == 3,
                    ),
                  ],
                ),
              ),
              verticalSpacing(20),
              ActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RouteHelper.reports);
                  },
                  actionText: 'Generate Report'),
              verticalSpacing(30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _headerText(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF8696BB),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _upperSummaryWidget(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _checkBoxesWidget(
  BuildContext context, {
  required Function onTap,
  required Color borderColor,
  required String label,
  required bool isSelected, // Add a parameter to indicate selection
}) {
  return InkWell(
    onTap: () {
      onTap();
    },
    splashColor: Colors.grey,
    child: Ink(
      width: MediaQuery.of(context).size.width * 0.36,
      height: 46,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 0),
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Change to spaceBetween
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: black,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Circular selection indicator with padding
          Padding(
            padding: const EdgeInsets.only(right: 16), // Add right padding
            child: Container(
              width: 15, // Outer circle width
              height: 15, // Outer circle height
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // Outer circle is transparent
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 5, // Inner circle width
                  height: 5, // Inner circle height
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? borderColor : Colors.grey, // Inner circle color
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

Widget _datePickerWidget(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null && picked != selectedDate) {
          onDateSelected(picked);
        }
      },
      child: Container(
        width: 151,
        height: 44,
        margin: const EdgeInsets.only(bottom: 20, top: 10),
        padding: const EdgeInsets.only(left: 5, right: 5, top: 12),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 0),
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF8696BB),
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 0.12,
              ),
            ),
            verticalSpacing(5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Icon(
                    Icons.access_time_filled,
                    color: mainColor,
                    size: 20,
                  ),
                ),
                Text(
                  selectedDate != null
                      ? DateFormat('dd-MM-yy').format(selectedDate)
                      : 'Select Date',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 0.10,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }*/