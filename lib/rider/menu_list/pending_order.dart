import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';

class PendingOrdersPage extends StatefulWidget {
  @override
  _PendingOrdersPageState createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  Stream<QuerySnapshot> getPendingOrders() {
    return _firestore
        .collection('orders')
        .where('riderApprove', isEqualTo: false)
        .snapshots();
  }

  void acceptOrder(String orderId) async {
    User? user = _auth.currentUser; // Get logged-in rider
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No logged-in rider found")),
      );
      return;
    }

    String riderId = user.uid; // Get rider's UID

    await _firestore.collection('orders').doc(orderId).update({
      'riderApprove': true,
      'acceptedRiderId': riderId, // Save logged-in rider's ID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order accepted successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Orders',style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending orders.'));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              var orderData = order.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(orderData['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: ${orderData['userName']}"),
                      Text("Phone: ${orderData['userPhone']}"),
                      Text("Total Cost: ${orderData['totalCost']}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => acceptOrder(order.id),
                    child: const Text('Accept'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
