import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
