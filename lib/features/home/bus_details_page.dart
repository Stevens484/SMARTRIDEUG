import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/seat_layout_page.dart';

class BusDetailsPage extends StatelessWidget {
  final String busId;
  final String number;

  const BusDetailsPage({super.key, required this.busId, required this.number});

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
                  builder: (_) => SeatLayoutPage(busNumber: number),
                ),
              );
            },
            child: const Text('View Seat Layout'),
          ),
        ),
      ],
    );

    Widget mapPreview(Map<String, dynamic> busData) {
      final pickup = LatLng(
        (busData['latitude'] as num?)?.toDouble() ?? 0.3392,
        (busData['longitude'] as num?)?.toDouble() ?? 32.5736,
      );
      final routePoints = [
        pickup,
        LatLng(
          (busData['destinationLat'] as num?)?.toDouble() ?? 0.3516,
          (busData['destinationLng'] as num?)?.toDouble() ?? 32.6112,
        ),
      ];

      return GoogleMap(
        initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            infoWindow: InfoWindow(
              title: busData['pickupInfo']?.toString() ?? 'Pickup',
            ),
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('r'),
            points: routePoints,
            color: AppTheme.primaryGreen,
            width: 4,
          ),
        },
        zoomControlsEnabled: false,
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
                        SizedBox(height: 240, child: mapPreview(busData)),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }
}
