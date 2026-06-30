import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/repositories/dashboard_repository_impl.dart';
import '../../../core/constants/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DashboardRepositoryImpl _repository = DashboardRepositoryImpl();
  Set<Marker> _markers = {};
  bool _isLoading = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locations = await _repository.getLocationRecords();
    
    if (mounted) {
      setState(() {
        _markers = locations.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final lat = data[DatabaseHelper.columnLatitude] as double;
          final lng = data[DatabaseHelper.columnLongitude] as double;
          final timestamp = data[DatabaseHelper.columnTimestamp] as String;
          final accuracy = data[DatabaseHelper.columnAccuracy] as double;

          return Marker(
            markerId: MarkerId('location_$index'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'Location #${index + 1}',
              snippet: 'Time: ${DateFormat('HH:mm:ss').format(DateTime.parse(timestamp))}\nAccuracy: ±${accuracy.toStringAsFixed(1)}m',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              index == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
            ),
          );
        }).toSet();
        _isLoading = false;
      });

      // Fit camera to show all markers
      if (_markers.isNotEmpty && _mapController != null) {
        final bounds = _boundsFromMarkers(_markers);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    }
  }

  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCATION MAP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _markers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No location data to display', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _markers.first.position,
                    zoom: 15,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    final bounds = _boundsFromMarkers(_markers);
                    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                final bounds = _boundsFromMarkers(_markers);
                _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
              },
              backgroundColor: AppColors.emeraldBrand,
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
            )
          : null,
    );
  }
}
