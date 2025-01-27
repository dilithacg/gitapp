import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userShopID;

  @override
  void initState() {
    super.initState();
    _getUserShopID();
  }

  // Get the current user's shopID from the users collection
  Future<void> _getUserShopID() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userSnapshot = await _firestore.collection('users')
            .doc(currentUser.uid) // Assuming userID is the UID
            .get();

        if (userSnapshot.exists) {
          setState(() {
            _userShopID = userSnapshot['shopID'];
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userShopID == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Items'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My ads'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('items')
            .where('shopID', isEqualTo: _userShopID) // Filter items by shopID
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items available.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item['title'];
              final description = item['description'];
              final price = item['price'];
              final imageUrl = item['imageUrl'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: Image.network(imageUrl),
                  title: Text(title),
                  subtitle: Text(description),
                  trailing: Text('\Rs ${price.toString()}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
