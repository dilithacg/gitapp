import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';

import '../../rider/menu_list/map_page.dart';
import 'customermap.dart';

class MyOrdersScreen extends StatelessWidget {
  Future<void> navigateToMap(Map<String, dynamic> orderData, String orderId,
      BuildContext context) async {
    String shopID = orderData['shopID'] ?? '';

    double customerLat = (orderData['location']?['latitude'] ?? 0.0).toDouble();
    double customerLng =
    (orderData['location']?['longitude'] ?? 0.0).toDouble();

    try {
      DocumentSnapshot shopDoc =
      await FirebaseFirestore.instance.collection('shops').doc(shopID).get();

      if (shopDoc.exists) {
        Map<String, dynamic>? shopData =
        shopDoc.data() as Map<String, dynamic>?;

        double shopLat =
        (shopData?['splocation']?['latitude'] ?? 0.0).toDouble();
        double shopLng =
        (shopData?['splocation']?['longitude'] ?? 0.0).toDouble();

        double deliveryFee = (orderData['deliveryFee'] ?? 0.0).toDouble();

        debugPrint("Shop Location: Latitude: $shopLat, Longitude: $shopLng");
        debugPrint(
            "Customer Location: Latitude: $customerLat, Longitude: $customerLng");

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => CustomerMapPage(
              shopLatitude: shopLat,
              shopLongitude: shopLng,
              customerLatitude: customerLat,
              customerLongitude: customerLng,
              totalCost: orderData['totalCost']?.toString() ?? '0.0',
              orderId: orderId,
              deliveryFee: deliveryFee.toString(),
            ),
          ),
        );
      } else {
        debugPrint("Error: Shop document does not exist.");
      }
    } catch (e) {
      debugPrint("Error fetching shop location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userID', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No orders found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>; // Cast to Map<String, dynamic>
              final title = orderData['title'] ?? 'No Title';
              final totalCost = orderData['totalCost'] ?? 'No Price';
              final shopApprove = orderData['shopApprove'] ?? false;
              final riderApprove = orderData['riderApprove'] ?? false;
              final orderCompleted=orderData['orderCompleted'] ?? false;
              final itemID = orderData['itemID'];
              final acceptedRiderId = orderData['acceptedRiderId'];
              final shopID = orderData['shopID'] ?? 'No Shop ID';
              final location = orderData['location'] ?? 'No Location';

              final shopStatus = shopApprove ? 'Approved' : 'Pending';
              final riderStatus = riderApprove ? 'Approved' : 'Pending';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('items').doc(itemID).get(),
                builder: (context, itemSnapshot) {
                  if (itemSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Loading item details...'),
                        subtitle: Text('Please wait'),
                      ),
                    );
                  }

                  if (!itemSnapshot.hasData || !itemSnapshot.data!.exists) {
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text('Image not found'),
                      ),
                    );
                  }

                  final itemData = itemSnapshot.data!;
                  final imageUrl = itemData['imageUrl'] ?? '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: acceptedRiderId != null
                        ? FirebaseFirestore.instance.collection('users').doc(acceptedRiderId).get()
                        : null,
                    builder: (context, riderSnapshot) {
                      String riderName = "Not Assigned";
                      String riderPhone = "N/A";
                      String riderVehicle = "Not Assigned";
                      if (riderSnapshot.hasData && riderSnapshot.data!.exists) {
                        final riderData = riderSnapshot.data!;
                        riderName = riderData['name'] ?? 'Unknown';
                        riderPhone = riderData['phone'] ?? 'Unknown';
                        riderVehicle = riderData['vehicleNo'] ?? 'Unknown';
                      }

                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                  imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                )
                                    : Icon(Icons.image, size: 70),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Total: Rs ${totalCost.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        StatusChip(
                                          label: 'Shop: $shopStatus',
                                          color: shopApprove
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        StatusChip(
                                          label: 'Rider: $riderStatus',
                                          color: riderApprove
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Rider: $riderName',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Phone: $riderPhone',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Vehicle No: $riderVehicle',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      orderCompleted ? 'Order Completed' : 'Not Completed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),

                                    SizedBox(height: 6),
                                    if (shopApprove && riderApprove) // Show only when both are approved
                                      ElevatedButton(
                                        onPressed: () {
                                          navigateToMap(orderData, order.id, context);
                                        },
                                        child: Text("View Map"),
                                      ),
                                  ],
                                ),
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
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
