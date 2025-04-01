import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftapp/auth/loginscreen.dart';
import 'package:giftapp/const/colors.dart';



class Shopscreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Shopscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? username = "";
  String? profilePic = "";
  String? pdescription = "No description available";
  String? email = "";
  String? phone = "";
  String? shopname = ""; // Add a variable for the shop name

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      // Fetch user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['name'];
          email = userDoc['email'];
          phone = userDoc['phone'];
          profilePic = userDoc['profilePic'] ?? ''; // Update with Firestore field name
        });
      }

      // Fetch shop data based on the current user's ID (ownerId)
      QuerySnapshot shopDoc = await _firestore
          .collection('shops')
          .where('ownerId', isEqualTo: _user!.uid)
          .get();

      if (shopDoc.docs.isNotEmpty) {
        setState(() {
          shopname = shopDoc.docs.first['shopname'] ?? 'No shop name available';
        });
      }
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    await _auth.signOut(); // Sign the user out

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(

                      child: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/5457/5457134.png',
                        height: 200.0,
                        width: 200.0,
                        fit: BoxFit.cover,
                      ),

                    ),
                    SizedBox(height: 20),
                    Text(
                      username ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      shopname ?? 'Loading shop name...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: menuList.length,
                  itemBuilder: (context, index) {
                    final item = menuList[index];
                    return GestureDetector(
                      onTap: () {
                        if (item['path'] != null) {
                          Navigator.pushNamed(context, item['path']!);
                        }
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: AppColors.secondColor,
                        child: Center(
                          child: Text(
                            item['name']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Positioned logout button in the bottom-middle of the screen
          Positioned(
            bottom: 20, // Adjust the distance from the bottom
            left: MediaQuery.of(context).size.width / 2 - 50, // Center horizontally
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                backgroundColor: AppColors.thirdColor,
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String?>> menuList = [
    {'id': '1', 'name': 'My Ads', 'path': '/my-products'},
    {'id': '2', 'name': 'Orders', 'path': '/orders'},
    {'id': '5', 'name': 'Add Item', 'path': '/add-item'},
  ];
}
