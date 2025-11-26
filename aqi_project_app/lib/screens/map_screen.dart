import 'package:aqi_project/models/sensor_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final SensorData data;

  const MapScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Default to a known location (Bangalore) if GPS is 0.0
    final LatLng displayLoc = (data.latitude == 0.0 && data.longitude == 0.0)
        ? const LatLng(12.9716, 77.5946)
        : LatLng(data.latitude, data.longitude);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: displayLoc, initialZoom: 15.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aqi_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: displayLoc,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // GPS Info Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _mapStat("Lat", data.latitude.toStringAsFixed(4)),
                    _mapStat("Lng", data.longitude.toStringAsFixed(4)),
                    _mapStat("Alt", "${data.altitude.toStringAsFixed(1)}m"),
                    _mapStat("Speed", "${data.speed.toStringAsFixed(1)}km/h"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
