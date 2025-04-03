import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:giftapp/const/colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CustomerMapPage extends StatefulWidget {
  final double shopLatitude;
  final double shopLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final String totalCost;
  final String orderId;
  final String deliveryFee;

  CustomerMapPage({
    required this.shopLatitude,
    required this.shopLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.totalCost,
    required this.orderId,
    required this.deliveryFee,
  });

  @override
  _CustomerMapPageState createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends State<CustomerMapPage> {
  late GoogleMapController _mapController;
  LatLng? riderLocation;
  String riderName = "";
  String riderPhone = "";
  String vehicleNo = "";
  bool isLoading = true;
  List<LatLng> riderPath = [];
  final String apiKey = 'AIzaSyBBDYXPXdmxcOPHh5PxeACQPNKNA6kLKKo';

  @override
  void initState() {
    super.initState();
    _fetchRiderDetails();
  }

  Future<void> _fetchRiderDetails() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderSnapshot.exists) {
        var orderData = orderSnapshot.data() as Map<String, dynamic>;
        String acceptedRiderId = orderData['acceptedRiderId'];

        FirebaseFirestore.instance
            .collection('users')
            .doc(acceptedRiderId)
            .snapshots()
            .listen((riderSnapshot) {
          if (riderSnapshot.exists) {
            var riderData = riderSnapshot.data() as Map<String, dynamic>;
            setState(() {
              riderName = riderData['name'];
              riderPhone = riderData['phone'];
              vehicleNo = riderData['vehicleNo'];
              isLoading = false;
            });
          }
        });

        FirebaseFirestore.instance
            .collection('rider')
            .doc(acceptedRiderId)
            .snapshots()
            .listen((locationSnapshot) {
          if (locationSnapshot.exists) {
            var locationData = locationSnapshot.data() as Map<String, dynamic>;
            setState(() {
              riderLocation =
                  LatLng(locationData['latitude'], locationData['longitude']);
            });

            if (riderLocation != null) {
              riderPath.add(riderLocation!);
            }

            _fetchRoute(riderLocation!,
                LatLng(widget.customerLatitude, widget.customerLongitude));

            _mapController.animateCamera(
              CameraUpdate.newLatLng(riderLocation!),
            );
          }
        });
      }
    } catch (e) {
      print("Error fetching rider details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRoute(LatLng origin, LatLng destination) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey&mode=driving';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0]['legs'][0]['steps'];

          List<LatLng> polylinePoints = [];
          for (var step in route) {
            var polyline = step['polyline']['points'];
            polylinePoints.addAll(_decodePolyline(polyline));
          }

          setState(() {
            riderPath = polylinePoints;
          });
        } else {
          print("No routes found in the Directions API response.");
        }
      } else {
        print('Error fetching directions: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      while (true) {
        int byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) {
          break;
        }
      }
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      while (true) {
        int byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) {
          break;
        }
      }
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: MarkerId('shop'),
        position: LatLng(widget.shopLatitude, widget.shopLongitude),
        infoWindow: InfoWindow(title: 'Shop Location'),
      ),
      Marker(
        markerId: MarkerId('customer'),
        position: LatLng(widget.customerLatitude, widget.customerLongitude),
        infoWindow: InfoWindow(title: 'Customer Location'),
      ),
      if (riderLocation != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: riderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Rider Location'),
        ),
    };

    Set<Polyline> polylines = {
      Polyline(
        polylineId: PolylineId("riderPath"),
        visible: true,
        points: riderPath,
        color: Colors.blue,
        width: 5,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Map', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.customerLatitude, widget.customerLongitude),
                  zoom: 12,
                ),
                markers: markers,
                polylines: polylines,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Cost: ${widget.totalCost}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Delivery Fee: ${widget.deliveryFee}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Rider Details:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Name: $riderName',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Phone: $riderPhone',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Vehicle No: $vehicleNo',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
