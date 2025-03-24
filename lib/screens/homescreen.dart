import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import '../widget/itemlist.dart'; // Import your ItemList widget
import '../widget/slider.dart';  // Import your SliderPage widget

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
        children: [
          // SliderPage widget
          Container(
            padding: EdgeInsets.only(top: 25),
            height: 301.0, // Set a fixed height for the slider
            child: SliderPage(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ItemList(),
                  ),
                );
              },
              child: Text(
                "All items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.thirdColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Expanded(
            child: ItemList(), // Display ItemList below the Slider
          ),
        ],
      ),
    );
  }
}
