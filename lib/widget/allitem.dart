import 'package:flutter/material.dart';

import '../widget/itemlist.dart';

class AllItemsScreen extends StatelessWidget {
  const AllItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
        children: [

          // Adding space between title and the items list
          const SizedBox(height: 16),
          const Expanded(child: ItemList()), // List of items
        ],
      ),
    );
  }
}
