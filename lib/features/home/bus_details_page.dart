import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_map/flutter_map.dart'; // 🔥 REPLACES google_maps_flutter
import 'package:latlong2/latlong.dart'; // 🔥 FOR MAP COORDINATES
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/seat_layout_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class BusDetailsPage extends StatelessWidget {
  final String busId;
  final String routeId;
  final String number;
  final String? routeId;

  const BusDetailsPage({
    super.key,
    required this.busId,
<<<<<<< HEAD
    required this.routeId,
    required this.number,
=======
    required this.number,
    this.routeId,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget assignedRoute(Map<String, dynamic> busData) {
      final assignedRouteId =
          busData['routeId']?.toString() ??
          busData['currentRoute']?.toString() ??
          routeId;
      if (assignedRouteId == null || assignedRouteId.isEmpty) {
        return const Text('No route assigned yet.');
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(assignedRouteId)
            .snapshots(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          if (route == null) {
            return Text(
              busData['routeName']?.toString() ?? 'Assigned route unavailable',
            );
          }
          final routeName = route['name']?.toString() ?? 'Assigned route';
          final origin = route['origin']?.toString() ?? 'Unknown origin';
          final destination =
              route['destination']?.toString() ?? 'Unknown destination';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routeName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text('$origin → $destination'),
            ],
          );
        },
      );
    }

    Widget driverDetails(Map<String, dynamic> busData) {
      final driverId = busData['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) {
        return const Text('No driver is assigned to this bus yet.');
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(driverId)
            .snapshots(),
        builder: (context, snapshot) {
          final driver = snapshot.data?.data();
          if (driver == null) return const Text('Driver profile unavailable.');
          final name =
              driver['displayName']?.toString() ??
              driver['name']?.toString() ??
              'Assigned driver';
          final email = driver['email']?.toString();
          final employeeId = driver['employeeId']?.toString();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (email != null && email.isNotEmpty) Text(email),
              if (employeeId != null && employeeId.isNotEmpty)
                Text('Driver ID: $employeeId'),
            ],
          );
        },
      );
    }

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
                        'BUS ${busData['busNumber']?.toString() ?? number}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (busData['plateNumber'] ?? busData['plate'])
                                ?.toString() ??
                            'Plate not available',
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
                assignedRoute(busData),
                const SizedBox(height: 12),
                const Text(
                  'Driver',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                driverDetails(busData),
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
              final assignedRouteId =
                  busData['routeId']?.toString() ??
                  busData['currentRoute']?.toString() ??
                  routeId;
              if (assignedRouteId == null || assignedRouteId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This bus has no route assignment yet.'),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeatLayoutPage(
                    busId: busId,
<<<<<<< HEAD
                    routeId: routeId,
                    busNumber: number,
=======
                    busNumber: busData['busNumber']?.toString() ?? number,
                    routeId: assignedRouteId,
                    totalSeats: (busData['totalSeats'] as num?)?.toInt() ?? 1,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
<<<<<<< HEAD
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
=======
      final activeRouteId =
          busData['routeId']?.toString() ?? busData['currentRoute']?.toString();
      final resolvedRouteId = activeRouteId ?? routeId;
      if (resolvedRouteId == null || resolvedRouteId.isEmpty) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(resolvedRouteId)
            .snapshots(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          if (route == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: RouteMapPanel(
              routeId: resolvedRouteId,
              route: route,
              currentBus: busData,
            ),
          );
        },
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .snapshots(),
          builder: (context, snapshot) {
            final busNumber = snapshot.data?.data()?['busNumber']?.toString();
            return Text(
              'Bus ${busNumber?.isNotEmpty == true ? busNumber : number}',
            );
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnapshot) {
            if (!busSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final savedBus = busSnapshot.data!.data() ?? <String, dynamic>{};
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('busLocations')
                  .doc(busId)
                  .snapshots(),
              builder: (context, locationSnapshot) {
                final busData = <String, dynamic>{
                  ...savedBus,
                  ...?locationSnapshot.data?.data(),
                };
                final busNumber = busData['busNumber']?.toString() ?? number;
                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: detailsColumn({
                                ...busData,
                                'busNumber': busNumber,
                              }),
                            ),
                          ),
                          if ((busData['routeId'] ??
                                  busData['currentRoute'] ??
                                  routeId) !=
                              null)
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
                            detailsColumn({...busData, 'busNumber': busNumber}),
                            if ((busData['routeId'] ??
                                    busData['currentRoute'] ??
                                    routeId) !=
                                null) ...[
                              const SizedBox(height: 16),
                              SizedBox(height: 240, child: mapPreview(busData)),
                            ],
                          ],
                        ),
<<<<<<< HEAD
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
=======
                      );
              },
            );
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          },
        ),
      ),
    );
  }
}
