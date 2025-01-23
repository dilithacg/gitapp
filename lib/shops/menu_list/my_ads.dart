import 'package:flutter/material.dart';

class MyAdsScreen extends StatelessWidget {
  final List<Map<String, String>> ads = [
    {
      'title': 'iPhone 14 Pro',
      'description': 'Brand new, sealed pack',
      'price': '\$1200',
    },
    {
      'title': 'Mountain Bike',
      'description': 'Used for 6 months, good condition',
      'price': '\$300',
    },
    {
      'title': 'Gaming PC',
      'description': 'High specs, RTX 3080',
      'price': '\$1500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ads'),
      ),
      body: ListView.builder(
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(ad['title'] ?? ''),
              subtitle: Text(ad['description'] ?? ''),
              trailing: Text(
                ad['price'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add ad functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}