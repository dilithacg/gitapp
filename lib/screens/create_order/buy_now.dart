import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';
import 'package:permission_handler/permission_handler.dart';

import 'mapscreen.dart';
import 'payment_screen.dart'; // Import the PaymentScreen

class BuyNowScreen extends StatefulWidget {
  final String shopID;
  final double price;
  final String itemID;
  final String title;
  final String itemImage;

  const BuyNowScreen({
    Key? key,
    required this.shopID,
    required this.price,
    required this.itemID,
    required this.title,
    required this.itemImage,
  }) : super(key: key);

  @override
  _BuyNowScreenState createState() => _BuyNowScreenState();
}

class _BuyNowScreenState extends State<BuyNowScreen> {
  LatLng? _selectedLocation;
  LatLng? _shopLocation;
  double? _deliveryFee;
  double? _totalCost;

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission.isDenied || permission.isPermanentlyDenied) {
      if (permission.isPermanentlyDenied) {
        openAppSettings();
      } else {
        _requestLocationPermission();
      }
    } else {
      _pickLocation();
    }
  }

  Future<void> _pickLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng initialLocation = LatLng(position.latitude, position.longitude);

    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapScreen(initialLocation: initialLocation, shopLocation: _shopLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        _calculateDeliveryFee();
      });
    }
  }

  Future<void> _fetchShopLocation() async {
    try {
      DocumentSnapshot shopSnapshot =
      await FirebaseFirestore.instance.collection('shops').doc(widget.shopID).get();

      if (shopSnapshot.exists) {
        final shopData = shopSnapshot.data() as Map<String, dynamic>;
        double lat = shopData['splocation']['latitude'];
        double lng = shopData['splocation']['longitude'];

        setState(() {
          _shopLocation = LatLng(lat, lng);
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch shop location: $error')),
      );
    }
  }

  void _calculateDeliveryFee() {
    if (_shopLocation != null && _selectedLocation != null) {
      double distanceInKm = Geolocator.distanceBetween(
        _shopLocation!.latitude,
        _shopLocation!.longitude,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      ) /
          1000;

      double baseFee = 250; // First 10 km fee
      double additionalFee = 0;

      // Calculate additional fee for distance beyond 10 km
      if (distanceInKm > 10) {
        additionalFee = (distanceInKm - 10) * 20;
      }

      double totalFee = baseFee + additionalFee;

      setState(() {
        _deliveryFee = totalFee;
        _totalCost = widget.price + totalFee;
      });
    }
  }

  void _placeOrder(BuildContext context) async {
    try {
      final userID = FirebaseAuth.instance.currentUser?.uid;

      if (userID == null) throw Exception('User not logged in!');

      final userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userID).get();
      if (!userSnapshot.exists) throw Exception('User details not found!');

      final userData = userSnapshot.data()!;
      final userName = userData['name'];
      final userPhone = userData['phone'];

      if (_selectedLocation == null) {
        throw Exception('Please select your location.');
      }

      await FirebaseFirestore.instance.collection('orders').add({
        'shopID': widget.shopID,
        'price': widget.price,
        'itemID': widget.itemID,
        'title': widget.title,
        'timestamp': Timestamp.now(),
        'userID': userID,
        'userName': userName,
        'userPhone': userPhone,
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'deliveryFee': _deliveryFee,
        'totalCost': _totalCost,
        'shopApprove': false,
        'riderApprove': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // Navigate to the PaymentScreen after the order is placed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            totalCost: _totalCost ?? 0.0,  // Pass the total cost to the PaymentScreen
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchShopLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Now', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.itemImage,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Price: Rs ${widget.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    if (_deliveryFee != null)
                      Text(
                        'Delivery Fee: Rs ${_deliveryFee!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    if (_totalCost != null)
                      Text(
                        'Total: Rs ${_totalCost!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _requestLocationPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Select Location',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            if (_selectedLocation != null)
              Text(
                'Selected Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _placeOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
