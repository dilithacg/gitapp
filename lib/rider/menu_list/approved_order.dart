import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';
import 'map_page.dart';

class AcceptedOrdersPage extends StatefulWidget {
  const AcceptedOrdersPage({super.key});

  @override
  _AcceptedOrdersPageState createState() => _AcceptedOrdersPageState();
}

class _AcceptedOrdersPageState extends State<AcceptedOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getAcceptedOrders() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('acceptedRiderId', isEqualTo: user.uid)
        .where('riderApprove', isEqualTo: true)
        .snapshots();
  }

  Future<void> navigateToMap(
      Map<String, dynamic> orderData, String orderId) async {
    String shopID = orderData['shopID'] ?? '';

    // Get customer location from order data
    double customerLat = (orderData['location']?['latitude'] ?? 0.0).toDouble();
    double customerLng =
        (orderData['location']?['longitude'] ?? 0.0).toDouble();

    try {
      // Fetch shop location from Firestore using shopID
      DocumentSnapshot shopDoc =
          await _firestore.collection('shops').doc(shopID).get();

      if (shopDoc.exists) {
        Map<String, dynamic>? shopData =
            shopDoc.data() as Map<String, dynamic>?;

        // Extract shop location from 'splocation' map
        double shopLat =
            (shopData?['splocation']?['latitude'] ?? 0.0).toDouble();
        double shopLng =
            (shopData?['splocation']?['longitude'] ?? 0.0).toDouble();

        // Extract delivery fee from order data
        double deliveryFee = (orderData['deliveryFee'] ?? 0.0).toDouble();

        // Debug prints
        debugPrint("Shop Name: ${shopData?['shopName']}");
        debugPrint("Shop Location: Latitude: $shopLat, Longitude: $shopLng");
        debugPrint(
            "Customer Location: Latitude: $customerLat, Longitude: $customerLng");

        // Navigate to MapPage with actual locations and user details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPage(
              shopLatitude: shopLat,
              shopLongitude: shopLng,
              customerLatitude: customerLat,
              customerLongitude: customerLng,
              userName: orderData['userName'] ?? 'Unknown User',
              userPhone: orderData['userPhone'] ?? 'Unknown Phone',
              totalCost: orderData['totalCost']?.toString() ?? '0.0',
              orderId: orderId,
              deliveryFee:
                  deliveryFee.toString(), // Convert deliveryFee to String
            ),
          ),
        );
      } else {
        debugPrint("Error: Shop document does not exist for shopID: $shopID");
      }
    } catch (e) {
      debugPrint("Error fetching shop location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Orders',style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAcceptedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No accepted orders.'));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              var orderData = order.data() as Map<String, dynamic>;
              String orderId = order.id; // Get the orderId from the document ID

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(orderData['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: ${orderData['userName']}"),
                      Text("Phone: ${orderData['userPhone']}"),
                      Text("Total Cost: \Rs${orderData['totalCost']!.toStringAsFixed(2)}"),
                      Text(
                          "Delivery Fee: \Rs${orderData['deliveryFee']!.toStringAsFixed(2)?.toString() ?? '0.0'}"), // Display delivery fee
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () =>
                        navigateToMap(orderData, orderId), // Pass orderId here
                    child: const Text('Direction'),
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
