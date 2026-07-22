import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartrideug/core/models/bus_model.dart';
import 'package:smartrideug/core/models/stop_model.dart';
import 'package:smartrideug/features/map/bus_popup_widget.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0.3136, 32.5811);
  bool _isFollowingBus = true;

  static const List<LatLng> _routePoints = [
    LatLng(0.3136, 32.5811),
    LatLng(0.3180, 32.5780),
    LatLng(0.3220, 32.5760),
    LatLng(0.3292, 32.5711),
    LatLng(0.3340, 32.5675),
    LatLng(0.3300, 32.5650),
    LatLng(0.3260, 32.5680),
  ];

  static final List<StopModel> _stops = [
    StopModel(
      id: 'stop_1',
      name: 'Old Taxi Park',
      position: LatLng(0.3136, 32.5811),
    ),
    StopModel(
      id: 'stop_2',
      name: 'City Square',
      position: LatLng(0.3180, 32.5780),
    ),
    StopModel(
      id: 'stop_3',
      name: 'Wandegeya',
      position: LatLng(0.3220, 32.5760),
    ),
    StopModel(
      id: 'stop_4',
      name: 'Makerere Main Gate',
      position: LatLng(0.3292, 32.5711),
    ),
    StopModel(id: 'stop_5', name: 'CoCIS', position: LatLng(0.3340, 32.5675)),
    StopModel(
      id: 'stop_6',
      name: 'Mulago Hospital',
      position: LatLng(0.3300, 32.5650),
    ),
    StopModel(
      id: 'stop_7',
      name: 'Nakasero',
      position: LatLng(0.3260, 32.5680),
    ),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Live Bus Tracking',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF2563EB)),
            onPressed: () {
              setState(() => _isFollowingBus = true);
              _mapController.move(_currentPosition, 16);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 REAL DATA FROM FIRESTORE
        stream: FirebaseFirestore.instance
            .collection('buses')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load buses',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final buses = snapshot.data!.docs;

          if (buses.isEmpty) {
            return const Center(
              child: Text(
                'No active buses available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 🔥 Convert Firestore documents to BusModel
          final busModels = buses.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final geo = data['location'] as GeoPoint;
            return BusModel(
              id: doc.id,
              routeName: data['routeName'] ?? 'Unknown Route',
              position: LatLng(geo.latitude, geo.longitude),
              speed: (data['speed'] ?? 0.0).toDouble(),
              passengerCount: data['passengerCount'] ?? 0,
              availableSeats: data['availableSeats'] ?? data['totalSeats'] ?? 0,
              totalSeats: data['totalSeats'] ?? 40,
              status: data['status'] ?? 'active',
              lastUpdated: DateTime.now(),
            );
          }).toList();

          // Use the first bus for camera following
          if (busModels.isNotEmpty && _isFollowingBus) {
            _currentPosition = busModels.first.position;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(busModels.first.position, 16);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: busModels.isNotEmpty
                      ? busModels.first.position
                      : const LatLng(0.3136, 32.5811),
                  initialZoom: 16,
                  minZoom: 12,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() => _isFollowingBus = false),
                ),
                children: [
                  // 🔥 Dark Tile Layer
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mhl.smart_ride_ug',
                  ),

                  // 🔥 Route Polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),

                  // 🔥 Markers — ALL BUSES FROM FIRESTORE
                  MarkerLayer(
                    markers: [
                      ...busModels.map((bus) {
                        return Marker(
                          point: bus.position,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => BusPopupWidget(bus: bus),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Start marker
                      Marker(
                        point: _routePoints.first,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                      // End marker
                      Marker(
                        point: _routePoints.last,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 6,
                              ),
                            ],
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

                  // 🔥 Stop Markers
                  MarkerLayer(
                    markers: _stops.map((stop) {
                      return Marker(
                        point: stop.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '📍 ${stop.name}\nBuses approaching: 2\nEstimated arrival: 5 min',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF64748B),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Color(0xFF64748B),
                              size: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                      TextSourceAttribution('CARTO'),
                    ],
                  ),
                ],
              ),

              // 🔥 Bottom Info Bar
              if (busModels.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚌 ${busModels.first.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${busModels.first.speed.toStringAsFixed(0)} km/h • ${busModels.first.passengerCount}/${busModels.first.totalSeats} passengers',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${busModels.first.availableSeats} seats left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
