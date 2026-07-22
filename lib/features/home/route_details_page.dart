import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

class RouteDetailsPage extends StatefulWidget {
  final String routeId;

  const RouteDetailsPage({super.key, required this.routeId});

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _routeFuture;
  late Future<QuerySnapshot<Map<String, dynamic>>> _busesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _routeFuture = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeId)
        .get();

    _busesFuture = FirebaseFirestore.instance
        .collection('busLocations')
        .where('routeId', isEqualTo: widget.routeId)
        .where('status', whereIn: ['online', 'moving', 'approaching_stop'])
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Details'), elevation: 0),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _routeFuture,
        builder: (context, routeSnapshot) {
          if (routeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (routeSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load route',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loadData());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final routeData = routeSnapshot.data?.data();
          final routeName = routeData?['name']?.toString() ?? 'Unknown Route';
          final origin = routeData?['origin']?.toString() ?? 'Unknown';
          final destination =
              routeData?['destination']?.toString() ?? 'Unknown';

          final originLat =
              (routeData?['originLat'] as num?)?.toDouble() ?? 0.3136;
          final originLng =
              (routeData?['originLng'] as num?)?.toDouble() ?? 32.5811;
          final destLat =
              (routeData?['destinationLat'] as num?)?.toDouble() ?? 0.3292;
          final destLng =
              (routeData?['destinationLng'] as num?)?.toDouble() ?? 32.5711;

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _busesFuture,
            builder: (context, busesSnapshot) {
              final buses = busesSnapshot.hasData
                  ? busesSnapshot.data!.docs
                  : [];
              final busCount = buses.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 Route Info
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(origin),
                                const SizedBox(width: 16),
                                const Icon(Icons.arrow_forward, size: 16),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.flag,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(destination),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: busCount > 0
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$busCount active buses',
                                    style: TextStyle(
                                      color: busCount > 0
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔥 Map Preview
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (originLat + destLat) / 2,
                                (originLng + destLng) / 2,
                              ),
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      LatLng(originLat, originLng),
                                      LatLng(destLat, destLng),
                                    ],
                                    strokeWidth: 4,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(originLat, originLng),
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  Marker(
                                    point: LatLng(destLat, destLng),
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
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
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔥 Active Buses List
                    if (buses.isNotEmpty) ...[
                      const Text(
                        'Active Buses on Route',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...buses.map((bus) {
                        final data = bus.data();
                        final busId = bus.id;
                        final busNumber =
                            data['busNumber']?.toString() ?? 'Unknown';
                        final status = data['status']?.toString() ?? 'Online';
                        final seats =
                            data['availableSeats']?.toString() ?? 'N/A';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_bus),
                            ),
                            title: Text('Bus $busNumber'),
                            subtitle: Text(
                              'Status: $status • $seats seats available',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BusDetailsPage(
                                    busId: busId,
                                    routeId: widget.routeId,
                                    number: busNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],

                    if (buses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No active buses on this route right now',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
