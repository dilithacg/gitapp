import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import the smooth_page_indicator package

class SliderPage extends StatefulWidget {
  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  late Future<List<String>> sliderImages;
  final CarouselSliderController _carouselController = CarouselSliderController(); // Correct controller for CarouselSlider
  int _currentIndex = 0; // Track the current index of the carousel

  @override
  void initState() {
    super.initState();
    sliderImages = fetchSliderImages();
  }

  // Fetch image URLs from Firestore
  Future<List<String>> fetchSliderImages() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('slider').get();
    List<String> imageUrls = [];
    for (var doc in snapshot.docs) {
      imageUrls.add(doc['sliderImg']); // Assuming the field is 'sliderImg'
    }
    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: sliderImages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No images available.'));
          } else {
            return Column(
              children: [
                // CarouselSlider wrapped with Container to define a standard size
                Container(
                  height: 250.0, // Fixed height for the slider
                  child: CarouselSlider(
                    carouselController: _carouselController, // Attach the controller here
                    items: snapshot.data!.map((imageUrl) {
                      return Builder(
                        builder: (BuildContext context) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12), // Adjust the radius as needed
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity, // Ensures it fills the container width
                            ),
                          );
                        },
                      );

                    }).toList(),
                    options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0, // Ensure full width usage
                      enableInfiniteScroll: true,
                      scrollPhysics: ClampingScrollPhysics(),
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index; // Update the index when the page changes
                        });
                      },
                    ),
                  ),
                ),
                // SmoothPageIndicator wrapped in Padding
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmoothPageIndicator(
                    controller: PageController(initialPage: _currentIndex),  // Use PageController here
                    count: snapshot.data!.length,
                    effect: WormEffect(
                      dotWidth: 10.0,
                      dotHeight: 10.0,
                      spacing: 16.0,
                      dotColor: Colors.grey,
                      activeDotColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
