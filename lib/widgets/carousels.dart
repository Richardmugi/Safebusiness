import 'dart:async'; // Import the async package for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ImageCarosel extends StatelessWidget {
  final List<String> imageList;
  const ImageCarosel({required this.imageList, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // 🔻 Reduce this to shrink carousel height
      child: CarouselSlider(
        options: CarouselOptions(
          height: 220.0, // 🔻 Smaller height
          enlargeCenterPage: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.8, // 🔻 Show part of next image
        ),
        items: imageList.map((imagePath) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 160, // 🔻 Match height
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
