import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import 'package:giftapp/rider/riderscreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class MapPage extends StatefulWidget {
  final double shopLatitude;
  final double shopLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final String userName;
  final String userPhone;
  final String totalCost;
  final String orderId;
  final String deliveryFee;

  const MapPage({
    super.key,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.userName,
    required this.userPhone,
    required this.totalCost,
    required this.orderId,
    required this.deliveryFee, // Accepting orderId
  });

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  late LatLng _shopLocation;
  late LatLng _customerLocation;
  bool _toShop = true;
  bool _giftPickedUp = false;

  Set<Polyline> _polylines = {};
  final String _apiKey = 'AIzaSyBBDYXPXdmxcOPHh5PxeACQPNKNA6kLKKo';

  @override
  void initState() {
    super.initState();
    _shopLocation = LatLng(widget.shopLatitude, widget.shopLongitude);
    _customerLocation =
        LatLng(widget.customerLatitude, widget.customerLongitude);
    _getCurrentLocation();
    _listenToLocationChanges();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _getRoute();
    });
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null) return;

    LatLng startLocation =
    LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng endLocation = _toShop ? _shopLocation : _customerLocation;

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${endLocation.latitude},${endLocation.longitude}&key=$_apiKey';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        List<LatLng> routePoints = _decodePolyline(
            response.data['routes'][0]['overview_polyline']['points']);
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: routePoints,
            )
          };
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching directions: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  void _switchRoute() {
    setState(() {
      _toShop = !_toShop;
      if (!_toShop) _giftPickedUp = false;
      _getRoute(); // Fetch updated route when switching
    });

    if (_mapController != null) {
      LatLng endLocation = _toShop ? _shopLocation : _customerLocation;
      _mapController!.animateCamera(CameraUpdate.newLatLng(endLocation));
    }
  }

  void _confirmDelivery() async {
    // Reference to Firestore
    CollectionReference orders =
    FirebaseFirestore.instance.collection('orders');

    try {
      // Update the specific order document with orderId
      await orders.doc(widget.orderId).update({'orderCompleted': true});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order delivered successfully!')),
      );

      // Navigate to the RiderHomeScreen
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => RiderHomeScreen()),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error updating order: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm delivery: $e')),
      );
    }
  }

  void _confirmGiftPickup() {
    setState(() {
      _giftPickedUp = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gift picked up successfully!')),
    );
  }

  void _updateRiderLocation(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ignore: avoid_print
        print('No user logged in.');
        return;
      }
      final String riderId = user.uid;
      await FirebaseFirestore.instance.collection('rider').doc(riderId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // ignore: avoid_print
      print('Rider location updated in Firestore.');
    } catch (e) {
      // ignore: avoid_print
      print('Error updating rider location: $e');
    }
  }

  void _listenToLocationChanges() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location if moved 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _getRoute(); // Fetch new route when location updates
      });

      // Update the map camera position.
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }

      // Save the updated location to Firestore.
      _updateRiderLocation(position);
    });
  }

  double _calculateDistance() {
    if (_currentPosition == null) return 0.0;
    LatLng endLocation = _toShop ? _shopLocation : _customerLocation;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      endLocation.latitude,
      endLocation.longitude,
    ) /
        1000; // Convert to kilometers
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    LatLng startLocation =
    LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng endLocation = _toShop ? _shopLocation : _customerLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _toShop ? 'To Shop' : 'To Customer',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                  CameraPosition(target: startLocation, zoom: 15),
                  markers: {
                    Marker(
                      markerId: const MarkerId('rider'),
                      position: startLocation,
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                    Marker(
                      markerId: MarkerId(_toShop ? 'shop' : 'customer'),
                      position: endLocation,
                      infoWindow: InfoWindow(
                          title:
                          _toShop ? 'Shop Location' : 'Customer Location'),
                    ),
                  },
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _toShop
                        ? 'Navigating to Shop'
                        : 'Delivering Order to Customer',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Distance: ${_calculateDistance().toStringAsFixed(2)} km', // Display distance
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (!_toShop) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Customer: ${widget.userName}', // Display user name
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Phone: ${widget.userPhone}', // Display user phone
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Total Cost: ${widget.totalCost}', // Display total cost
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _confirmDelivery(); // Confirm delivery and navigate
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor),
                      child: const Text('Confirm Delivery',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (_toShop) ...[
                    ElevatedButton(
                      onPressed: _switchRoute,
                      child: const Text('Switch Route'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _giftPickedUp ? null : _confirmGiftPickup,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _giftPickedUp
                              ? Colors.grey
                              : AppColors.primaryColor),
                      child: Text(
                        _giftPickedUp ? 'Gift Picked Up ✅' : 'Pick Up Gift',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
