import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../const/colors.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Show feedback dialog for both Item and Rider
  void _showFeedbackDialog(String itemID, String riderID) {
    TextEditingController itemFeedbackController = TextEditingController();
    TextEditingController riderFeedbackController = TextEditingController();
    int itemRating = 1;
    int riderRating = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate Your Order & Rider'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating & Feedback for Item
                    Text('Rate the Ordered Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            itemRating > index ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              itemRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    TextField(
                      controller: itemFeedbackController,
                      decoration: InputDecoration(
                        labelText: 'Enter feedback for the item',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),

                    // Rating & Feedback for Rider
                    Text('Rate the Rider:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            riderRating > index ? Icons.star : Icons.star_border,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              riderRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    TextField(
                      controller: riderFeedbackController,
                      decoration: InputDecoration(
                        labelText: 'Enter feedback for the rider',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (itemFeedbackController.text.trim().isEmpty ||
                        riderFeedbackController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter feedback for both item and rider')),
                      );
                      return;
                    }

                    // Store feedback for the ordered item
                    await _firestore
                        .collection('items')
                        .doc(itemID)
                        .collection('feedbacks')
                        .add({
                      'rating': itemRating,
                      'feedback': itemFeedbackController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'userId': _auth.currentUser!.uid,
                    });

                    // Store feedback for the rider
                    await _firestore
                        .collection('users')
                        .doc(riderID)
                        .collection('feedbacks')
                        .add({
                      'rating': riderRating,
                      'feedback': riderFeedbackController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'userId': _auth.currentUser!.uid,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Feedback submitted successfully')),
                    );
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: FutureBuilder<User?>(
        future: Future.value(_auth.currentUser),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          String userId = userSnapshot.data!.uid;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('orders')
                .where('userID', isEqualTo: userId)
                .where('orderCompleted', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No completed orders found.'));
              }

              var orders = snapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var order = orders[index];
                  String itemID = order['itemID'];
                  String riderID = order['acceptedRiderId'];
                  Timestamp timestamp = order['timestamp'];
                  String formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
                      .format(timestamp.toDate());

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('items').doc(itemID).get(),
                    builder: (context, itemSnapshot) {
                      if (!itemSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      String imageUrl = itemSnapshot.data!.get('imageUrl');

                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(riderID).get(),
                        builder: (context, riderSnapshot) {
                          if (!riderSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          String riderName = riderSnapshot.data!.get('name');

                          return Card(
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              leading: Image.network(imageUrl,
                                  width: 50, height: 50, fit: BoxFit.cover),
                              title: Text(order['title']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price: LKR ${order['price']}'),
                                  Text('Delivery Fee: LKR ${order['deliveryFee']}'),
                                  Text('Total: LKR ${order['totalCost']}'),
                                  Text('Delivered by: $riderName',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(formattedDate,
                                      style: TextStyle(color: Colors.grey)),
                                  SizedBox(height: 5),
                                  ElevatedButton(
                                    onPressed: () {
                                      _showFeedbackDialog(itemID, riderID);
                                    },
                                    child: Text('Rate & Give Feedback'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
