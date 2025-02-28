import 'dart:io';
import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _userId = "";
  XFile? _image;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPickingImage = false; // Flag to track if an image is being picked

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      _userId = user.uid; // Get user ID
      // Fetch user details from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          // Set the controllers with the fetched data
          _nameController.text = data['name'] ?? "";
          _emailController.text = data['email'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _image = data['profileImage'] != null
              ? XFile(data['profileImage'])
              : null; // Assuming profile image URL is stored in Firestore
        });
      }
    } else {
      // Handle user not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return; // Prevent multiple calls
    _isPickingImage = true; // Set the flag to true

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });
    }

    _isPickingImage = false; // Reset the flag after the process is complete
  }

  Future<String?> _uploadImage(File image) async {
    try {
      // Create a reference to Firebase Storage
      Reference ref = _storage.ref().child('profile_images/${_userId}.jpg');

      // Upload the image to Firebase Storage
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL of the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch existing user data from Firestore for comparison
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_userId).get();
        var existingData = userDoc.data() as Map<String, dynamic>;

        bool updated = false; // Flag to track if any updates are made

        // Update email if it has changed
        if (_emailController.text != existingData['email']) {
          await user.updateEmail(_emailController.text);
          updated = true;
        }

        // Upload image if a new one has been picked
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(File(_image!.path));
          updated = true;
        }

        // Update user details in Firestore only if they have changed
        if (_nameController.text != existingData['name'] ||
            _phoneController.text != existingData['phone'] ||
            imageUrl != null) {
          await _firestore.collection('users').doc(_userId).update({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'profileImage': imageUrl ??
                existingData['profileImage'], // Update image URL if available
          });
          updated = true;
        }

        if (updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No changes detected.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page',style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _image != null ? FileImage(File(_image!.path)) : null,
                child: _image == null ? Icon(Icons.camera_alt, size: 50) : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              controller: _nameController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              controller: _emailController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Phone'),
              controller: _phoneController,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
