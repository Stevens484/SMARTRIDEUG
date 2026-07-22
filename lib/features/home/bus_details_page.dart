import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 🔥 REPLACES google_maps_flutter
import 'package:latlong2/latlong.dart'; // 🔥 FOR MAP COORDINATES
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/seat_layout_page.dart';

class BusDetailsPage extends StatelessWidget {
  final String busId;
  final String routeId;
  final String number;

  const BusDetailsPage({
    super.key,
    required this.busId,
    required this.routeId,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget detailsColumn(Map<String, dynamic> busData) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 36,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUS $number',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        busData['plate']?.toString() ?? 'Plate not available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          (busData['status']?.toString() ?? 'On Route')
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: busData['status'] == 'offline'
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  busData['routeName']?.toString() ??
                      'Route details not available',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Driver',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  busData['driverName']?.toString() ??
                      'Driver details not available',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pickup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  busData['pickupInfo']?.toString() ??
                      'Pickup information not available',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeatLayoutPage(
                    busId: busId,
                    routeId: routeId,
                    busNumber: number,
                  ),
                ),
              );
            },
            child: const Text('View Seat Layout'),
          ),
        ),
      ],
    );

    // 🔥 NEW: Map preview using FlutterMap (free, no API keys)
    Widget mapPreview(Map<String, dynamic> busData) {
      // Get pickup location from bus data, with fallback
      final pickupLat = (busData['latitude'] as num?)?.toDouble() ?? 0.3392;
      final pickupLng = (busData['longitude'] as num?)?.toDouble() ?? 32.5736;
      final destLat = (busData['destinationLat'] as num?)?.toDouble() ?? 0.3516;
      final destLng =
          (busData['destinationLng'] as num?)?.toDouble() ?? 32.6112;

      final pickup = LatLng(pickupLat, pickupLng);
      final destination = LatLng(destLat, destLng);

      return Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: pickup,
              initialZoom: 14,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              // 🔥 Dark tile layer (same as live map)
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.mhl.smart_ride_ug',
              ),
              // 🔥 Route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, destination],
                    strokeWidth: 4,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
              // 🔥 Markers: pickup (green) and destination (red)
              MarkerLayer(
                markers: [
                  // Pickup marker
                  Marker(
                    point: pickup,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // Destination marker
                  Marker(
                    point: destination,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              // 🔥 Attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  TextSourceAttribution('CARTO'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bus $number'), elevation: 0),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('busLocations')
              .doc(busId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final busData = snapshot.data!.data() ?? <String, dynamic>{};
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: detailsColumn(busData),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: mapPreview(busData),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        detailsColumn(busData),
                        const SizedBox(height: 16),
                        mapPreview(busData),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }
}
