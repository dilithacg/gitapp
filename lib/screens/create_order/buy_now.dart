import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giftapp/const/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'mapscreen.dart';

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

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission.isDenied || permission.isPermanentlyDenied) {
      // If permission is denied, request again or open app settings
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
        builder: (context) => MapScreen(initialLocation: initialLocation, shopLocation: _shopLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  Future<void> _fetchShopLocation() async {
    try {
      DocumentSnapshot shopSnapshot = await FirebaseFirestore.instance.collection('shops').doc(widget.shopID).get();

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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      Navigator.pop(context);
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
        title: const Text('Buy Now'),
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

class MapScreen extends StatefulWidget {
  final LatLng initialLocation;
  final LatLng? shopLocation;

  const MapScreen({
    Key? key,
    required this.initialLocation,
    this.shopLocation,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  LatLng? _selectedLocation;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _controller.animateCamera(
      CameraUpdate.newLatLngZoom(widget.initialLocation, 14),
    );
  }

  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation,
                zoom: 14,
              ),
              onMapCreated: _onMapCreated,
              onTap: _onTap,
              markers: {
                if (widget.shopLocation != null)
                  Marker(
                    markerId: const MarkerId('shopLocation'),
                    position: widget.shopLocation!,
                    infoWindow: const InfoWindow(title: 'Shop Location'),
                  ),
                if (_selectedLocation != null)
                  Marker(
                    markerId: const MarkerId('selectedLocation'),
                    position: _selectedLocation!,
                  ),
              },
            ),
          ),
          ElevatedButton(
            onPressed: _confirmSelection,
            child: const Text('Confirm Location'),
          ),
        ],
      ),
    );
  }
}
