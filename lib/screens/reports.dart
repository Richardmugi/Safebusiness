import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/utils/color_resources.dart';

import '../widgets/custom_divider.dart';
import '../widgets/sized_box.dart';

class Report extends StatelessWidget {
  const Report({super.key});
  static const routeName = '/report';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            verticalSpacing(25),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_outlined, size: 20)),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Text(
                    'Back',
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
                color: const Color(0xFFD9D9D9)),
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
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      verticalSpacing(10),
                      Text(
                        '10-02-23 to 16-10-23',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8696BB),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  // second colum
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/magnifying-glass.png',
                            color: mainColor,
                            width: 20,
                            height: 20,
                          ),
                          horizontalSpacing(10),
                          Image.asset(
                            'assets/icons/filter.png',
                            width: 20,
                            height: 20,
                            color: mainColor,
                          )
                        ],
                      ),
                      verticalSpacing(15),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            color: mainColor),
                        child: const Center(
                            child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Download',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                        )),
                      )
                    ],
                  )
                ],
              ),
            ),
            verticalSpacing(40),

            // MAIN CONTAINER
            mainDataContainer(context,
                title1: 'Mon',
                title2: 'Check In',
                title3: 'Check Out',
                title4: 'Status',
                val1: '12/02/23',
                val2: '09:00 AM',
                val3: '05:00 PM',
                val4: 'Late Arrival',
                val4Color: const Color(0xFFFF8D05)),
            verticalSpacing(20),
            mainDataContainer(context,
                title1: 'Tue',
                title2: 'Check In',
                title3: 'Check Out',
                title4: 'Status',
                val1: '12/02/23',
                val2: '08:00 AM',
                val3: '05:00 PM',
                val4: 'On time',
                val4Color: const Color(0xFF389916)),
            verticalSpacing(20),
            mainDataContainer(context,
                title1: 'Wed',
                title2: 'Check In',
                title3: 'Check Out',
                title4: 'Status',
                val1: '12/02/23',
                val2: '09:00 AM',
                val3: '07:00 PM',
                val4: 'Over time',
                val4Color: const Color(0xFF389916)),
            verticalSpacing(20),
            mainDataContainer(context,
                title1: 'Thur',
                title2: 'Check In',
                title3: 'Check Out',
                title4: 'Status',
                val1: '12/02/23',
                val2: '0:00 AM',
                val3: '0:00 PM',
                val4: 'Absent',
                val4Color: mainColor)
          ],
        ),
        ),
      ),
    );
  }

  Widget mainDataContainer(BuildContext context,
      {required String title1,
      required String title2,
      required String title3,
      required String title4,
      required String val1,
      required String val2,
      required String val3,
      required String val4,
      required Color val4Color}) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24),
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
        //mainAxisAlignment: MainAxisAlignment.space,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title1),
              verticalSpacing(2),
              _headerText(val1)
            ],
          ),
          horizontalSpacing(MediaQuery.of(context).size.width * 0.067),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title2),
              verticalSpacing(2),
              _headerText(val2)
            ],
          ),
          horizontalSpacing(MediaQuery.of(context).size.width * 0.067),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title3),
              verticalSpacing(2),
              _headerText(val3)
            ],
          ),
          horizontalSpacing(MediaQuery.of(context).size.width * 0.067),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTextBold(title4),
              verticalSpacing(2),
              _headerText(val4, color: val4Color)
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerTextBold(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF8696BB),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _headerText(String title, {Color color = const Color(0xFF8696BB)}) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
