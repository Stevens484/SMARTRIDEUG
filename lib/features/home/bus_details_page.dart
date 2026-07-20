import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/seat_layout_page.dart';

class BusDetailsPage extends StatelessWidget {
  final String number;
  final String plate;

  const BusDetailsPage({super.key, required this.number, required this.plate});

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;
    final pickup = const LatLng(0.3392, 32.5736);
    final routePoints = [
      pickup,
      const LatLng(0.345, 32.587),
      const LatLng(0.3516, 32.6112),
    ];

    Widget detailsColumn() => Column(
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
                      Text(plate, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text(
                          'On Route',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
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
              children: const [
                Text('Route', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Makerere → Wandegeya → Mulago → Ntinda'),
                SizedBox(height: 12),
                Text('Driver', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('John Ssemmenda • 4.8 ★'),
                SizedBox(height: 12),
                Text('Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Makerere Main Gate — Next in 4 min'),
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

    Widget mapPreview() => GoogleMap(
      initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
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

    return Scaffold(
      appBar: AppBar(title: Text('Bus $number'), elevation: 0),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: detailsColumn(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: mapPreview(),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    detailsColumn(),
                    const SizedBox(height: 16),
                    SizedBox(height: 240, child: mapPreview()),
                  ],
                ),
              ),
      ),
    );
  }
}
