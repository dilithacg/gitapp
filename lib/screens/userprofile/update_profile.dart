import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';
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
  final TextEditingController _businessRegNoController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  LatLng? _selectedLocation;

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw "User not logged in";
      if (_selectedLocation == null) throw "Please select a location on the map.";

      DocumentReference shopRef = await _firestore.collection('shops').add({
        'shopName': _shopNameController.text.trim(),
        'city': _cityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'businessRegNo': _businessRegNoController.text.trim(),
        'nicNumber': _nicController.text.trim(),
        'ownerId': userId,
        'splocation': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'adminApprove': false,
      });

      await _firestore.collection('users').doc(userId).update({
        'shopId': shopRef.id,
        'role': 'shop',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop profile updated successfully!')),
      );

      Navigator.pop(context);
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

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(controller: _shopNameController, label: 'Shop Name'),
              _buildTextField(controller: _cityController, label: 'City'),
              _buildTextField(controller: _phoneController, label: 'Phone Number'),
              _buildTextField(controller: _businessRegNoController, label: 'Business Registration Number'),
              _buildTextField(controller: _nicController, label: 'NIC Number'),
              const SizedBox(height: 20),
              const Text('Select Shop Location:'),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(6.9271, 79.8612),
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
                  : Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _updateProfile,
                  child: const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
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
    _businessRegNoController.dispose();
    _nicController.dispose();
    super.dispose();
  }
}
