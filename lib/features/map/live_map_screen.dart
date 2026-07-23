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
  bool _isFollowingBus = true;
  BusModel? _selectedBus;

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

  void _selectBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
      _isFollowingBus = true;
      _mapController.move(bus.position, 16);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
              if (_selectedBus != null) {
                _mapController.move(_selectedBus!.position, 16);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BusModel>>(
        stream: _simulationService.simulateMultipleBuses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final buses = snapshot.data!;

          if (_selectedBus == null && buses.isNotEmpty) {
            _selectedBus = buses.first;
          }

          if (_isFollowingBus && _selectedBus != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(_selectedBus!.position, 16);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: buses.isNotEmpty
                      ? buses.first.position
                      : const LatLng(0.3136, 32.5811),
                  initialZoom: 15,
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
                  // 🔥 BUS MARKERS WITH FLOATING INFO — FIXED OVERFLOW
                  MarkerLayer(
                    markers: buses.map((bus) {
                      final isSelected = _selectedBus?.id == bus.id;
                      final color = bus.seatColor;
                      return Marker(
                        point: bus.position,
                        width: 80,
                        height: 70,
                        child: GestureDetector(
                          onTap: () {
                            _selectBus(bus);
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => BusPopupWidget(bus: bus),
                            );
                          },
                          child: Column(
                            children: [
                              // 🔥 FLOATING INFO BUBBLE — CONTAINED WITH MAX WIDTH
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      screenWidth * 0.45, // 🔥 Prevent overflow
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: color,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          bus.id,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          '${bus.availableSeats} seats',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 7,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primary : color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Start & End markers
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _routePoints.first,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      Marker(
                        point: _routePoints.last,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 12,
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
                        width: 32,
                        height: 32,
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
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: AppTheme.grey500,
                              size: 12,
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
              // 🔥 BOTTOM TAPABLE BAR — FIXED OVERFLOW
              Positioned(
                bottom: 16,
                left: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildColorDot(Colors.green, 'Available'),
                          const SizedBox(width: 10),
                          _buildColorDot(Colors.orange, 'Limited'),
                          const SizedBox(width: 10),
                          _buildColorDot(Colors.red, 'Full'),
                        ],
                      ),
                      const Divider(height: 6, thickness: 0.5),
                      // Bus list
                      ...buses.map((bus) {
                        final isSelected = _selectedBus?.id == bus.id;
                        return GestureDetector(
                          onTap: () => _selectBus(bus),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primarySoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: bus.seatColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  bus.id,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 11,
                                    color: AppTheme.grey900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    bus.routeName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.grey500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${bus.availableSeats} seats',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: bus.seatColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: AppTheme.grey500,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildColorDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: AppTheme.grey500)),
      ],
    );
  }
}
