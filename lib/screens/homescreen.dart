import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import '../widget/allitem.dart';
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
          Padding(
            padding: const EdgeInsets.only(top: 25),  // Using const for padding
            child: Container(
              height: 301.0, // Consider making this dynamic if needed
              child:  SliderPage(), // Marking SliderPage as const
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Using const for padding
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllItemsScreen(),
                  ),
                );
              },
              child: const Text(
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
            child: const ItemList(), // Marking ItemList as const for optimization
          ),
        ],
      ),
    );
  }
}
