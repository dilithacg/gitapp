import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  LatLng? _selectedLocation; // Stores the selected location

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw "User not logged in";

      if (_selectedLocation == null) throw "Please select a location on the map.";

      // Create a shop document in "shops" collection
      DocumentReference shopRef = await _firestore.collection('shops').add({
        'shopName': _shopNameController.text.trim(),
        'city': _cityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ownerId': userId,
        'splocation': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the user document in "users" collection with shopId and role
      await _firestore.collection('users').doc(userId).update({
        'shopId': shopRef.id,
        'role': 'shop',  // Set the role as "shop"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop profile updated successfully!')),
      );

      Navigator.pop(context); // Go back after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Shop Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Shop Name'),
              ),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Text('Select Shop Location:'),
              Container(
                height: 300,
                decoration: BoxDecoration(border: Border.all()),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(6.9271, 79.8612), // Default location (Colombo, Sri Lanka)
                    zoom: 12,
                  ),
                  onTap: _onMapTapped,
                  markers: _selectedLocation != null
                      ? {
                    Marker(
                      markerId: const MarkerId('selectedLocation'),
                      position: _selectedLocation!,
                    )
                  }
                      : {},
                ),
              ),
              const SizedBox(height: 10),
              if (_selectedLocation != null)
                Text(
                  'Selected Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
