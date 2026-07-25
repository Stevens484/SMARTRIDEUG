import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/models/stop_model.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(0.3320, 32.5705); // Makerere-ish

  // busId -> latest known data from busLocations
  final Map<String, Map<String, dynamic>> _buses = {};
  // busId -> accumulated trail of real positions seen this session
  final Map<String, List<LatLng>> _trails = {};

  bool _hasCentered = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const List<Color> _palette = [
    AppTheme.primary,
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  static final List<StopModel> _stops = [
    StopModel(
      id: 'stop_1',
      name: 'Old Taxi Park',
      position: const LatLng(0.3136, 32.5811),
    ),
    StopModel(
      id: 'stop_2',
      name: 'City Square',
      position: const LatLng(0.3180, 32.5780),
    ),
    StopModel(
      id: 'stop_3',
      name: 'Wandegeya',
      position: const LatLng(0.3220, 32.5760),
    ),
    StopModel(
      id: 'stop_4',
      name: 'Makerere Main Gate',
      position: const LatLng(0.3292, 32.5711),
    ),
    StopModel(
      id: 'stop_5',
      name: 'CoCIS',
      position: const LatLng(0.3340, 32.5675),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // A real subscription set up once, outside the widget build cycle —
    // this is what actually fixes the "setState during build" crash.
    _sub = FirebaseFirestore.instance
        .collection('busLocations')
        .where('status', whereIn: ['online', 'moving', 'approaching_stop'])
        .snapshots()
        .listen(_onSnapshot);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color _colorFor(String busId) =>
      _palette[busId.hashCode.abs() % _palette.length];

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      _buses[doc.id] = data;
      final point = LatLng(lat, lng);
      final trail = _trails.putIfAbsent(doc.id, () => []);
      if (trail.isEmpty || trail.last != point) {
        trail.add(point);
        if (trail.length > 300) trail.removeAt(0); // cap memory use
      }
    }
    _buses.removeWhere((id, _) => !snapshot.docs.any((d) => d.id == id));

    if (!_hasCentered && _buses.isNotEmpty) {
      _hasCentered = true;
      final first = _buses.values.first;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lng = (first['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(LatLng(lat, lng), 16);
        });
      }
    }

    // This callback runs from the Firestore SDK, completely outside of any
    // widget build phase, so calling setState here is always safe.
    if (mounted) setState(() {});
  }

  void _openBusSheet(String busId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BusInfoSheet(busId: busId, data: data),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
            if (_buses.isEmpty) return;
            final first = _buses.values.first;
            final lat = (first['latitude'] as num?)?.toDouble();
            final lng = (first['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              _mapController.move(LatLng(lat, lng), 16);
            }
          },
        ),
      ],
    ),
    body: _buses.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No buses are online right now.\nAsk a driver to go online '
                'from the Driver dashboard.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 15,
                  minZoom: 12,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mhl.smart_ride_ug',
                  ),
                  PolylineLayer(
                    polylines: _trails.entries
                        .where((e) => e.value.length > 1)
                        .map(
                          (e) => Polyline(
                            points: e.value,
                            strokeWidth: 4,
                            color: _colorFor(e.key),
                          ),
                        )
                        .toList(),
                  ),
                  MarkerLayer(
                    markers: _stops
                        .map(
                          (stop) => Marker(
                            point: stop.position,
                            width: 34,
                            height: 34,
                            child: GestureDetector(
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('📍 ${stop.name}')),
                                  ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.grey300,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: AppTheme.grey500,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  MarkerLayer(
                    markers: _buses.entries.map((entry) {
                      final busId = entry.key;
                      final data = entry.value;
                      final lat = (data['latitude'] as num).toDouble();
                      final lng = (data['longitude'] as num).toDouble();
                      final color = _colorFor(busId);
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _openBusSheet(busId, data),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
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
            ],
          ),
  );
}

/// The sheet shown when a passenger taps a bus icon — real trip info,
/// pulled from the route the bus is actually on, plus a way to book it.
class _BusInfoSheet extends StatelessWidget {
  const _BusInfoSheet({required this.busId, required this.data});
  final String busId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final routeId = data['routeId']?.toString();
    final busNumber = data['busNumber']?.toString() ?? busId;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: routeId == null
            ? null
            : FirebaseFirestore.instance
                  .collection('routes')
                  .doc(routeId)
                  .get(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          final origin = route?['origin']?.toString() ?? 'Unknown';
          final destination = route?['destination']?.toString() ?? 'Unknown';

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bus $busNumber',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.route, size: 18, color: AppTheme.grey500),
                  const SizedBox(width: 6),
                  Expanded(child: Text('$origin → $destination')),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Status: ${data['status'] ?? 'unknown'}'),
                ],
              ),
              if (data['availableSeats'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.event_seat,
                      size: 18,
                      color: AppTheme.grey500,
                    ),
                    const SizedBox(width: 6),
                    Text('${data['availableSeats']} seats available'),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event_seat),
                  label: const Text('Book this bus'),
                  onPressed: routeId == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BusDetailsPage(
                                busId: busId,
                                routeId: routeId,
                                number: busNumber,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
