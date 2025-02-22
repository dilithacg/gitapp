import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: currentUserId)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications available"));
          }

          var notifications = snapshot.data!.docs;

          // Debugging: Print notifications in the console
          debugPrint("Fetched ${notifications.length} notifications");

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notificationDoc = notifications[index];
              var notification = notificationDoc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(notification["message"] ?? "No message"),
                  subtitle: notification.containsKey("timestamp") && notification["timestamp"] != null
                      ? Text(
                    "Time: ${DateFormat('dd MMM yyyy, hh:mm a').format((notification["timestamp"] as Timestamp).toDate())}",
                    style: TextStyle(color: Colors.grey),
                  )
                      : Text("No timestamp"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
