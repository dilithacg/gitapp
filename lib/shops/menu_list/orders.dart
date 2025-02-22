import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? shopId;

  @override
  void initState() {
    super.initState();
    _fetchUserShopId();
  }

  Future<void> _fetchUserShopId() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection("users").doc(userId).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData.containsKey("shopId")) {
        setState(() {
          shopId = userData["shopId"];
        });
      } else {
        print("shopId field is missing in users collection");
      }
    }
  }

  void _updateOrderStatus(String orderId, String userId, bool isAccepted) async {
    await FirebaseFirestore.instance.collection("orders").doc(orderId).update({
      "shopApprove": isAccepted,
    });

    // Create a notification entry
    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": userId,
      "orderId": orderId,
      "message": isAccepted
          ? "Your order has been accepted by the shop."
          : "Your order has been canceled by the shop.",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shop Orders")),
      body: shopId == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("shopID", isEqualTo: shopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No orders available"));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderDoc = orders[index];
              var order = orderDoc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(order["title"] ?? "No title"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Cost: ${order["totalCost"]?.toStringAsFixed(2)}"),
                      Text("Delivery Fee: ${order["deliveryFee"]?.toStringAsFixed(2)}"),
                      Text("User: ${order["userName"]}"),
                      Text("Phone: ${order["userPhone"]}"),
                      if (order.containsKey("timestamp") && order["timestamp"] != null)
                        Text(
                          "Ordered On: ${DateFormat('dd MMM yyyy, hh:mm a').format((order["timestamp"] as Timestamp).toDate())}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: order["shopApprove"] == true
                      ? Text(
                    "Accepted",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _updateOrderStatus(orderDoc.id, order["userID"], true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text(
                          "Accept",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _updateOrderStatus(orderDoc.id, order["userID"], false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
