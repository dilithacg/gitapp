import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/screens/userprofile/update_profile.dart';


import '../auth/loginscreen.dart'; // Replace with your actual login screen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.jpg'), // Replace with actual image
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'johndoe@example.com',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildButton(context, 'My Orders', Icons.shopping_bag, () {
              // Navigate to My Orders screen
            }),
            _buildButton(context, 'History', Icons.history, () {
              // Navigate to History screen
            }),
            _buildButton(context, 'Update Profile', Icons.edit, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
              );
            }),
            const Spacer(), // Pushes the logout button to the middle-bottom
            _buildLogoutButton(context),
            const SizedBox(height: 20), // Add spacing from bottom
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50), // Full-width button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut();
          // Navigate to login screen after logout
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with your actual login screen
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
        minimumSize: const Size(double.infinity, 50), // Full-width button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
