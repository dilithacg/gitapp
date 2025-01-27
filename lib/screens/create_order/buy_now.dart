import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyNowScreen extends StatelessWidget {
  final String shopID;
  final double price;
  final String itemID;
  final String title;
  final String itemImage;

  const BuyNowScreen({
    Key? key,
    required this.shopID,
    required this.price,
    required this.itemID,
    required this.title,
    required this.itemImage,
  }) : super(key: key);

  void _placeOrder(BuildContext context) async {
    try {
      final userID = FirebaseAuth.instance.currentUser?.uid;

      if (userID == null) {
        throw Exception('User not logged in!');
      }

      final userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userID).get();
      if (!userSnapshot.exists) {
        throw Exception('User details not found!');
      }

      final userData = userSnapshot.data()!;
      final userName = userData['name'];
      final userPhone = userData['phone'];

      await FirebaseFirestore.instance.collection('orders').add({
        'shopID': shopID,
        'price': price,
        'itemID': itemID,
        'title': title,
        'timestamp': Timestamp.now(),
        'userID': userID,
        'userName': userName,
        'userPhone': userPhone,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Now'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  itemImage,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Price: Rs $price',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Confirm Order Button
            ElevatedButton(
              onPressed: () => _placeOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
