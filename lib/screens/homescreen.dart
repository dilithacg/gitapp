import 'package:flutter/material.dart';
import '../widget/itemlist.dart'; // Import your ItemList widget
import '../widget/slider.dart';  // Import your SliderPage widget

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          // SliderPage widget
          Container(
            padding: EdgeInsets.only(top: 25),
            height: 301.0, // Set a fixed height for the slider
            child: SliderPage(),
          ),
          // ItemList widget
          Expanded(
            child: ItemList(), // Display ItemList below the Slider
          ),
        ],
      ),
    );
  }
}
