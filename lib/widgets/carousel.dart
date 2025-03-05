import 'dart:async'; // Import the async package for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int current = 0;
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer; // Declare a Timer variable

  List<String> sliders = [
    "https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&w=1770&q=80",
    "https://images.unsplash.com/photo-1580870069867-74c57ee1bb07?auto=format&fit=crop&w=2835&q=80",
    "https://images.unsplash.com/photo-1580618864180-f6d7d39b8ff6?auto=format&fit=crop&w=1769&q=80",
    "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&w=870&q=80"
  ];

  @override
  void initState() {
    super.initState();
    // Start the timer to change the page every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (current < sliders.length - 1) {
        current++;
      } else {
        current = 0; // Reset to the first image
      }
      _pageController.animateToPage(
        current,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {}); // Update the state to reflect the current page
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: sliders.length,
            onPageChanged: (index) {
              setState(() {
                current = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  child: CachedNetworkImage(
                    imageUrl: sliders[index],
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        height: 100.0,
                        width: 200.0,
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey,
                          highlightColor: Colors.grey.shade600,
                          child: const Icon(
                            CarbonIcons.image,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: SizedBox(
                        height: 100.0,
                        width: 200.0,
                        child: Icon(CarbonIcons.image_copy),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: sliders.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                entry.key,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              child: Container(
                width: current == entry.key ? 15 : 5.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: current == entry.key ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: current == entry.key ? BorderRadius.circular(5.0) : null,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.redAccent
                          : Colors.red)
                      .withOpacity(
                    current == entry.key ? 0.9 : 0.4,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}