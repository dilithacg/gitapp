import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';
import 'package:giftapp/rider/menu_list/approved_order.dart';
import 'package:giftapp/rider/menu_list/completed_order.dart';
import 'package:giftapp/rider/menu_list/pending_order.dart';
import 'package:giftapp/rider/menu_list/rider_user_profile.dart';


import '../auth/loginscreen.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> imageList = [
      'assets/images/login.png',
      'assets/images/shoploc.png',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rider',style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Slider
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            items: imageList.map((imagePath) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Grid View Buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  buildSquareButton(context, 'Pending Orders', Icons.pending,
                      Colors.redAccent, '/pending-order'),
                  buildSquareButton(context, 'Accepted Orders',
                      Icons.check_circle, Colors.green, '/accepted-order'),
                  buildSquareButton(context, 'Completed Orders', Icons.done_all,
                      Colors.blue, '/completed-order'),
                  buildSquareButton(context, 'User Profile', Icons.person,
                      Colors.orange, '/user-profile'),
                ],
              ),
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget buildSquareButton(BuildContext context, String title, IconData icon,
      Color color, String? route) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: route != null
          ? () {
        switch (route) {
          case '/pending-order':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingOrdersPage(),
              ),
            );
            break;
          case '/accepted-order':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AcceptedOrdersPage(),
              ),
            );
            break;
          case '/completed-order':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompletedOrdersPage(),
              ),
            );
            break;
          case '/user-profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            );
            break;
          default:
            break;
        }
      }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}')),
          );
        }
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text('Logout', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
