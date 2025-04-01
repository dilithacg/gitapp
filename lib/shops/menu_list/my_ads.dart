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
  String? _userShopId;

  @override
  void initState() {
    super.initState();
    _getUserShopId();
  }

  // Fetch shopId from users collection based on logged-in user ID
  Future<void> _getUserShopId() async {
    try {
      final user = _auth.currentUser; // Get the currently logged-in user
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userShopId = userDoc.data()?['shopId']; // Extract shopId
          });
        } else {
          print('User document does not exist.');
        }
      }
    } catch (e) {
      print('Error fetching shopId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userShopId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Ads'),
        ),
        body: Center(
          child: Text('Loading your ads...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Ads'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('items')
            .where('shopId', isEqualTo: _userShopId) // Filter by shopId
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('An error occurred. Please try again.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No items found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item['title'];

              final price = item['price'];
              final imageUrl = item['imageUrl'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4, // Add elevation for shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(Icons.image, size: 50),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  trailing: Text(
                    'Rs ${price.toString()}',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
