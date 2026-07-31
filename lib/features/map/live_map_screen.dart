import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/models/bus_model.dart';
import 'package:smartrideug/core/services/osrm_routing_service.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/map/bus_popup_widget.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _mapController = MapController();
  final _repository = TransitRepository();
  final _routing = OsrmRoutingService();
  static const _initialPosition = LatLng(0.3238, 32.5736);

  BusModel? _selectedBus;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _journeyPoints = const [];
  Duration? _eta;
  String? _locationMessage;
  String? _routingMessage;

  @override
  void initState() {
    super.initState();
    _requestCurrentLocation();
  }

  void _moveTo(LatLng point, {double zoom = 16}) =>
      _mapController.move(point, zoom);

  Future<void> _requestCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted)
        setState(
          () => _locationMessage =
              'Turn on location services to see your position.',
        );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted)
        setState(
          () => _locationMessage = 'Location permission was not granted.',
        );
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = location;
        _locationMessage = null;
      });
      _moveTo(location);
      await _drawJourney();
    } on TimeoutException {
      if (mounted)
        setState(
          () => _locationMessage =
              'Finding your location is taking too long. Try again.',
        );
    } catch (_) {
      if (mounted)
        setState(
          () => _locationMessage = 'Unable to get your current location.',
        );
    }
  }

  Future<void> _drawJourney() async {
    final origin = _currentLocation;
    final destination = _destination;
    if (origin == null || destination == null) return;
    setState(() => _routingMessage = null);
    try {
      final route = await _routing.route(
        origin: origin,
        destination: destination,
      );
      if (mounted)
        setState(() {
          _journeyPoints = route.points;
          _eta = route.duration;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _journeyPoints = [origin, destination];
          _routingMessage = 'ETA is unavailable; showing a direct route.';
        });
    }
  }

  void _setDestination(TapPosition _, LatLng point) {
    setState(() => _destination = point);
    _drawJourney();
  }

  void _showBusDetails(BusModel bus) {
    setState(() => _selectedBus = bus);
    _moveTo(bus.position);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BusPopupWidget(bus: bus),
    );
  }

  Color _busColor(BusModel bus) => bus.seatColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.grey50,
    appBar: AppBar(
      title: const Text('Live Bus Tracking'),
      backgroundColor: AppTheme.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.my_location, color: Colors.white),
          tooltip: 'Show my location',
          onPressed: _currentLocation == null
              ? _requestCurrentLocation
              : () => _moveTo(_currentLocation!),
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.routes(),
      builder: (context, routesSnapshot) {
        final routes =
            routesSnapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        return StreamBuilder<List<BusModel>>(
          stream: _repository.liveBusModels(),
          builder: (context, snapshot) {
            final buses = snapshot.data ?? const <BusModel>[];
            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialPosition,
                    initialZoom: 14,
                    onLongPress: _setDestination,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smartrideug',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                    _ConfiguredRoutePolylines(routes: routes),
                    PolylineLayer(
                      polylines: [
                        if (_journeyPoints.isNotEmpty)
                          Polyline(
                            points: _journeyPoints,
                            color: AppTheme.primaryDark,
                            strokeWidth: 5,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ...buses.map(
                          (bus) => Marker(
                            point: bus.position,
                            width: 48,
                            height: 48,
                            child: GestureDetector(
                              onTap: () => _showBusDetails(bus),
                              child: Icon(
                                Icons.directions_bus,
                                color: _busColor(bus),
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.my_location,
                              color: AppTheme.primary,
                              size: 30,
                            ),
                          ),
                        if (_destination != null)
                          Marker(
                            point: _destination!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.pink,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                if (buses.isEmpty &&
                    snapshot.connectionState != ConnectionState.waiting)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No live buses are currently available.'),
                      ),
                    ),
                  ),
                if (_locationMessage != null || _routingMessage != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _messageCard(_locationMessage ?? _routingMessage!),
                  ),
                if (_eta != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('ETA: ${_eta!.inMinutes} min'),
                      ),
                    ),
                  ),
                _busList(buses),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _messageCard(String message) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: _requestCurrentLocation,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _busList(List<BusModel> buses) => Positioned(
    bottom: 16,
    left: 8,
    right: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  @override
  void didUpdateWidget(covariant _ConfiguredRoutePolylines oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _signatureFor(widget.routes);
    if (nextSignature != _routeSignature) {
      for (final route in widget.routes) {
        _geometryService.invalidate(route.id);
      }
      _loadRoutes();
    }
  }

  void _loadRoutes() {
    _routeSignature = _signatureFor(widget.routes);
    _routeLines = Future.wait(
      widget.routes.map((route) async {
        try {
          final geometry = await _geometryService.resolve(
            routeId: route.id,
            route: route.data(),
          );
          return _MapRouteLine(id: route.id, geometry: geometry);
        } catch (_) {
          return null;
        }
      }),
    ).then((routes) => routes.whereType<_MapRouteLine>().toList());
  }

  String _signatureFor(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> routes,
  ) => routes
      .map((route) => '${route.id}:${route.data()['updatedAt']}')
      .join('|');

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_MapRouteLine>>(
    future: _routeLines,
    builder: (context, snapshot) {
      final routes = snapshot.data ?? const <_MapRouteLine>[];
      const routeColors = [
        AppTheme.primary,
        Color(0xFF2563EB),
        Color(0xFF9333EA),
        Color(0xFFF97316),
      ];
      return PolylineLayer(
        polylines: [
          for (var index = 0; index < routes.length; index++)
            Polyline(
              points: routes[index].geometry.points,
              color: routeColors[index % routeColors.length],
              strokeWidth: 5,
            ),
        ],
      );
    },
  );
}

class _MapRouteLine {
  const _MapRouteLine({required this.id, required this.geometry});

  final String id;
  final RouteGeometry geometry;
}
