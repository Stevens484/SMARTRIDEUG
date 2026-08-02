import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

/// Shows available route lines and the live buses assigned to each route.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _mapController = MapController();
  final _geometryService = RouteGeometryService();
  static const _defaultCenter = LatLng(0.3320, 32.5705);

  // busId -> latest live data from busLocations.
  final Map<String, Map<String, dynamic>> _liveBuses = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _busSubscription;
  Future<List<_LiveRoute>>? _routeLinesFuture;
  String? _routeSignature;
  bool _hasCentered = false;

  static const _routeColors = [
    AppTheme.primary,
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _busSubscription = FirebaseFirestore.instance
        .collection('busLocations')
        .where(
          'status',
          whereIn: const [
            'active',
            'online',
            'moving',
            'approaching_stop',
            'on_route',
            'on route',
          ],
        )
        .snapshots()
        .listen(_onBusSnapshot);
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }

  void _onBusSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final visibleIds = <String>{};
    for (final document in snapshot.docs) {
      final data = document.data();
      if (_positionFor(data) == null) continue;
      visibleIds.add(document.id);
      _liveBuses[document.id] = data;
    }
    _liveBuses.removeWhere((id, _) => !visibleIds.contains(id));

    if (!_hasCentered && _liveBuses.isNotEmpty) {
      _hasCentered = true;
      final position = _positionFor(_liveBuses.values.first);
      if (position != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(position, 15);
        });
      }
    }
    if (mounted) setState(() {});
  }

  LatLng? _positionFor(Map<String, dynamic> data) {
    final latitude = data['currentLatitude'] ?? data['latitude'];
    final longitude = data['currentLongitude'] ?? data['longitude'];
    if (latitude is! num || longitude is! num) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  Future<List<_LiveRoute>> _routeLinesFor(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final available = documents
        .where((document) => document.data()['active'] != false)
        .toList();
    final signature = available
        .map(
          (document) =>
              '${document.id}:${document.data()['updatedAt'] ?? ''}:${document.data()['polyline'] ?? ''}',
        )
        .join('|');
    if (_routeLinesFuture != null && _routeSignature == signature) {
      return _routeLinesFuture!;
    }
    _routeSignature = signature;
    _routeLinesFuture = Future.wait(
      available.indexed.map(
        (entry) => _resolveRoute(entry.$2, entry.$1 % _routeColors.length),
      ),
    ).then((routes) => routes.whereType<_LiveRoute>().toList());
    return _routeLinesFuture!;
  }

  Future<_LiveRoute?> _resolveRoute(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    int colorIndex,
  ) async {
    try {
      final data = document.data();
      final geometry = await _geometryService.resolve(
        routeId: document.id,
        route: data,
      );
      return _LiveRoute(
        id: document.id,
        name: data['name']?.toString() ?? document.id,
        destination: data['destination']?.toString() ?? 'Destination',
        color: _routeColors[colorIndex],
        geometry: geometry,
      );
    } catch (_) {
      // A route without configured coordinates cannot be drawn yet.
      return null;
    }
  }

  void _openBusSheet(String busId, Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BusInfoSheet(busId: busId, liveData: data),
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
      foregroundColor: AppTheme.grey900,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back, color: AppTheme.grey900),
      ),
      elevation: 0,
      actions: [
        IconButton(
          tooltip: 'Show live buses',
          icon: const Icon(Icons.my_location, color: AppTheme.primary),
          onPressed: () {
            if (_liveBuses.isEmpty) return;
            final position = _positionFor(_liveBuses.values.first);
            if (position != null) _mapController.move(position, 15);
          },
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('routes').snapshots(),
      builder: (context, routeSnapshot) {
        final routeDocuments = routeSnapshot.data?.docs ?? const [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('buses').snapshots(),
          builder: (context, busSnapshot) {
            final savedBuses = <String, Map<String, dynamic>>{
              for (final document in busSnapshot.data?.docs ?? const [])
                document.id: document.data(),
            };
            return FutureBuilder<List<_LiveRoute>>(
              future: _routeLinesFor(routeDocuments),
              builder: (context, lineSnapshot) {
                final routes = lineSnapshot.data ?? const <_LiveRoute>[];
                return Stack(
                  children: [
                    _map(routes, savedBuses),
                    if (lineSnapshot.connectionState == ConnectionState.waiting)
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: _MapNotice(label: 'Loading available routes...'),
                      ),
                    if (_liveBuses.isEmpty)
                      const Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: _MapNotice(
                          label:
                              'No buses are live right now. Route lines remain visible.',
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    ),
  );

  Widget _map(
    List<_LiveRoute> routes,
    Map<String, Map<String, dynamic>> savedBuses,
  ) {
    final routeById = {for (final route in routes) route.id: route};
    final buses = <String, Map<String, dynamic>>{
      for (final entry in _liveBuses.entries)
        entry.key: {...?savedBuses[entry.key], ...entry.value},
    };
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 13,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mhl.smartrideug',
        ),
        PolylineLayer(
          polylines: routes
              .map(
                (route) => Polyline(
                  points: route.geometry.points,
                  strokeWidth: 5,
                  color: route.color.withValues(alpha: .78),
                ),
              )
              .toList(),
        ),
        MarkerLayer(
          markers: [
            ...routes.expand(
              (route) => [
                _routeEndpoint(
                  route.geometry.origin,
                  Icons.trip_origin_rounded,
                  route.color,
                  '${route.name} origin',
                ),
                _routeEndpoint(
                  route.geometry.destination,
                  Icons.flag_rounded,
                  route.color,
                  '${route.name} destination',
                ),
                ...route.geometry.stops.map(_routePointMarker),
              ],
            ),
            ...buses.entries.map((entry) {
              final data = entry.value;
              final position = _positionFor(data);
              if (position == null) return null;
              final routeId =
                  data['routeId']?.toString() ??
                  data['currentRoute']?.toString();
              final route = routeId == null ? null : routeById[routeId];
              // Do not draw a placeholder vehicle. Every marker on this map
              // must be a bus with a real assigned route and seat availability.
              if (route == null || data['availableSeats'] is! num) return null;
              return _busMarker(
                busId: entry.key,
                position: position,
                data: data,
                route: route,
              );
            }).whereType<Marker>(),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _routeEndpoint(
    LatLng position,
    IconData icon,
    Color color,
    String label, {
    double size = 38,
  }) => Marker(
    point: position,
    width: size,
    height: size,
    child: Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(icon, color: color, size: size * .55),
      ),
    ),
  );

  Marker _routePointMarker(RouteStop stop) {
    final isPickup =
        stop.type == 'pickup' ||
        stop.type == 'pickup_point' ||
        stop.type == 'pickup point';
    final isBoth = stop.type == 'both';
    return _routeEndpoint(
      stop.position,
      isPickup
          ? Icons.my_location_rounded
          : isBoth
          ? Icons.swap_vert_rounded
          : Icons.location_on_rounded,
      isPickup
          ? AppTheme.success
          : isBoth
          ? const Color(0xFF2878E8)
          : AppTheme.navy,
      '${isPickup
          ? 'Pickup'
          : isBoth
          ? 'Pickup & stop'
          : 'Stop'}: ${stop.name}',
      size: 34,
    );
  }

  Marker _busMarker({
    required String busId,
    required LatLng position,
    required Map<String, dynamic> data,
    required _LiveRoute route,
  }) {
    final color = route.color;
    final seats = (data['availableSeats'] as num).toInt().toString();
    final destination = route.destination;
    final status = _displayStatus(data['status']?.toString() ?? 'Online');
    return Marker(
      point: position,
      width: 136,
      height: 94,
      child: GestureDetector(
        onTap: () => _openBusSheet(busId, data),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 8),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            Positioned(
              top: 48,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 136),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$seats free · $status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.grey700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayStatus(String status) => status
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _LiveRoute {
  const _LiveRoute({
    required this.id,
    required this.name,
    required this.destination,
    required this.color,
    required this.geometry,
  });

  final String id;
  final String name;
  final String destination;
  final Color color;
  final RouteGeometry geometry;
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

/// Details shown when a passenger taps a tagged live bus icon.
class _BusInfoSheet extends StatelessWidget {
  const _BusInfoSheet({required this.busId, required this.liveData});
  final String busId;
  final Map<String, dynamic> liveData;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('buses')
        .doc(busId)
        .snapshots(),
    builder: (context, busSnapshot) {
      final data = <String, dynamic>{...?busSnapshot.data?.data(), ...liveData};
      final routeId =
          data['routeId']?.toString() ?? data['currentRoute']?.toString();
      final busNumber = data['busNumber']?.toString() ?? busId;
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: routeId == null
            ? null
            : FirebaseFirestore.instance
                  .collection('routes')
                  .doc(routeId)
                  .get(),
        builder: (context, routeSnapshot) {
          final route = routeSnapshot.data?.data();
          final origin = route?['origin']?.toString() ?? 'Unknown origin';
          final destination =
              route?['destination']?.toString() ?? 'Unknown destination';
          final seats =
              data['availableSeats']?.toString() ?? 'Seat availability pending';
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus $busNumber',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  _detailRow(Icons.route, '$origin → $destination'),
                  _detailRow(
                    Icons.circle,
                    'Status: ${data['status'] ?? 'unknown'}',
                  ),
                  _detailRow(Icons.event_seat, '$seats seats available'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.event_seat),
                      label: const Text('View bus and choose seats'),
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
              ),
            ),
          );
        },
      );
    },
  );

  Widget _detailRow(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grey500),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
