import 'dart:async'; // Import the async package for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:safebusiness/screens/info.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shimmer/shimmer.dart';

class ImageCarosel extends StatelessWidget {
  final List<String> imageList;
  const ImageCarosel({required this.imageList, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300, // overall height of carousel
      child: CarouselSlider(
        options: CarouselOptions(
          height: 300.0,
          enlargeCenterPage: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.8,
        ),
        items: imageList.map((imagePath) {
          return Builder(
            builder: (BuildContext context) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      //color: mainColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                      ),
                    ),
                  ),
//                   Positioned(
//                     top: 12,
//                     right: 12,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: mainColor,
//                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const UserInfoFormPage()),
// );

//                       },
//                       child: const Text(
//                         'Get Started',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
                ],
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
