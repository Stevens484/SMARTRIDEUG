import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
<<<<<<< HEAD
import 'package:smartrideug/core/models/stop_model.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

=======
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

/// Shows available route lines and the live buses assigned to each route.
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
<<<<<<< HEAD
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(0.3320, 32.5705); // Makerere-ish

  // busId -> latest known data from busLocations
  final Map<String, Map<String, dynamic>> _buses = {};
  // busId -> accumulated trail of real positions seen this session
  final Map<String, List<LatLng>> _trails = {};

  bool _hasCentered = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const List<Color> _palette = [
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
    AppTheme.primary,
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

<<<<<<< HEAD
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
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  }

  @override
  void dispose() {
<<<<<<< HEAD
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
=======
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
      showDragHandle: true,
      builder: (_) => _BusInfoSheet(busId: busId, liveData: data),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
<<<<<<< HEAD
          icon: const Icon(Icons.my_location, color: AppTheme.primary),
          onPressed: () {
            if (_buses.isEmpty) return;
            final first = _buses.values.first;
            final lat = (first['latitude'] as num?)?.toDouble();
            final lng = (first['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              _mapController.move(LatLng(lat, lng), 16);
            }
=======
          tooltip: 'Show live buses',
          icon: const Icon(Icons.my_location, color: AppTheme.primary),
          onPressed: () {
            if (_liveBuses.isEmpty) return;
            final position = _positionFor(_liveBuses.values.first);
            if (position != null) _mapController.move(position, 15);
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          },
        ),
      ],
    ),
<<<<<<< HEAD
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
=======
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
                ...route.geometry.stops.map(
                  (stop) => _routeEndpoint(
                    stop.position,
                    Icons.circle,
                    route.color,
                    stop.name,
                    size: 28,
                  ),
                ),
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        future: routeId == null
            ? null
            : FirebaseFirestore.instance
                  .collection('routes')
                  .doc(routeId)
                  .get(),
<<<<<<< HEAD
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: buses
            .map(
              (bus) => ListTile(
                dense: true,
                leading: Icon(Icons.directions_bus, color: bus.seatColor),
                title: Text(bus.id),
                subtitle: Text(bus.routeName),
                trailing: Text('${bus.availableSeats} seats'),
                onTap: () => _showBusDetails(bus),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _ConfiguredRoutePolylines extends StatefulWidget {
  const _ConfiguredRoutePolylines({required this.routes});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> routes;

  @override
  State<_ConfiguredRoutePolylines> createState() =>
      _ConfiguredRoutePolylinesState();
}

class _ConfiguredRoutePolylinesState extends State<_ConfiguredRoutePolylines> {
  final _geometryService = RouteGeometryService();
  late Future<List<_MapRouteLine>> _routeLines;
  late String _routeSignature;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
=======
        builder: (context, routeSnapshot) {
          final route = routeSnapshot.data?.data();
          final origin = route?['origin']?.toString() ?? 'Unknown origin';
          final destination =
              route?['destination']?.toString() ?? 'Unknown destination';
          final seats =
              data['availableSeats']?.toString() ?? 'Seat availability pending';
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
}
