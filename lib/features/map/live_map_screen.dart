import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/models/bus_model.dart';
import 'package:smartrideug/core/models/stop_model.dart';
import 'package:smartrideug/core/services/bus_simulation_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/map/bus_popup_widget.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  final BusSimulationService _simulationService = BusSimulationService();
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
    _simulationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Live Bus Tracking',
          style: TextStyle(color: AppTheme.grey900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppTheme.primary),
            onPressed: () {
              setState(() => _isFollowingBus = true);
              _mapController.move(_currentPosition, 16);
            },
          ),
        ],
      ),
      body: StreamBuilder<BusModel>(
        // 🔥 USE SIMULATION — NOT FIRESTORE
        stream: _simulationService.simulateBusMovement(
          'BUS-001',
          'Route 4A - Kampala Loop',
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final bus = snapshot.data!;
          _currentPosition = bus.position;

          if (_isFollowingBus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(bus.position, 16);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: bus.position,
                  initialZoom: 16,
                  minZoom: 12,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() => _isFollowingBus = false),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mhl.smart_ride_ug',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Bus
                      Marker(
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
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Start
                      Marker(
                        point: _routePoints.first,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
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
                      // End
                      Marker(
                        point: _routePoints.last,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
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
                  // Stops
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.grey300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: AppTheme.grey500,
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
              // Bottom Info Bar
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
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
                              '🚌 ${bus.id}',
                              style: TextStyle(
                                color: AppTheme.grey900,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bus.speed.toStringAsFixed(0)} km/h • ${bus.passengerCount}/${bus.totalSeats} passengers',
                              style: TextStyle(
                                color: AppTheme.grey500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${bus.availableSeats} seats left',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
