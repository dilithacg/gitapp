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
  String? profilePic = ""; // Add user profile picture link if available
  String? pdescription = "No description available"; // Add a description field in Firestore if needed
  String? email = "";
  String? phone = "";

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'];
          email = userDoc['email'];
          phone = userDoc['phone'];
          profilePic = userDoc['profilePic'] ?? ''; // Update with Firestore field name
          pdescription = userDoc['pdescription'] ?? 'No description available';
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
        builder: (context) => LoginScreen(), // Ensure LoginScreen is the correct screen
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
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePic != null && profilePic!.isNotEmpty
                            ? NetworkImage(profilePic!)
                            : null,
                        child: profilePic == null || profilePic!.isEmpty
                            ? Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        pdescription ?? 'Loading...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey[200],
                        ),
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
    {'id': '2', 'name': 'Orders', 'path': null},
    {'id': '3', 'name': 'edit profile', 'path': null},
    {'id': '4', 'name': 'notification', 'path': null},
    {'id': '5', 'name': 'Add Item', 'path': '/add-item'},
  ];
}
