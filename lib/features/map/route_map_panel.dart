import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

/// Shared OpenStreetMap panel for passenger, driver, and route views.
class RouteMapPanel extends StatefulWidget {
  const RouteMapPanel({
    super.key,
    required this.routeId,
    required this.route,
    this.buses = const [],
    this.currentBus,
    this.height,
    this.onBusTap,
  });

  final String routeId;
  final Map<String, dynamic> route;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> buses;
  final Map<String, dynamic>? currentBus;
  final double? height;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>? onBusTap;

  @override
  State<RouteMapPanel> createState() => _RouteMapPanelState();
}

class _RouteMapPanelState extends State<RouteMapPanel> {
  final _map = MapController();
  final _geometryService = RouteGeometryService();
  late Future<RouteGeometry> _geometry;
  StreamSubscription<Position>? _passengerLocationSubscription;
  LatLng? _passengerLocation;
  String? _routeSignature;
  String? _fittedSignature;

  @override
  void initState() {
    super.initState();
    _loadGeometry();
    _watchPassengerLocation();
  }

  @override
  void didUpdateWidget(covariant RouteMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = '${widget.routeId}:${widget.route['updatedAt'] ?? ''}';
    if (signature != _routeSignature) {
      _loadGeometry();
    }
  }

  @override
  void dispose() {
    _passengerLocationSubscription?.cancel();
    super.dispose();
  }

  void _loadGeometry() {
    _routeSignature = '${widget.routeId}:${widget.route['updatedAt'] ?? ''}';
    _geometry = _geometryService.resolve(
      routeId: widget.routeId,
      route: widget.route,
    );
  }

  Future<void> _watchPassengerLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }
    _passengerLocationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 15,
          ),
        ).listen((position) {
          if (mounted) {
            setState(
              () => _passengerLocation = LatLng(
                position.latitude,
                position.longitude,
              ),
            );
          }
        });
  }

  void _fitRoute(RouteGeometry geometry) {
    final signature = '${widget.routeId}:${geometry.points.length}';
    if (_fittedSignature == signature) return;
    _fittedSignature = signature;
    final points = geometry.points;
    if (points.isEmpty) return;
    final minLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLng = points
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = points
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);
    final span = (maxLat - minLat).abs() > (maxLng - minLng).abs()
        ? (maxLat - minLat).abs()
        : (maxLng - minLng).abs();
    final zoom = span < .01
        ? 14.5
        : span < .03
        ? 13
        : span < .08
        ? 12
        : span < .2
        ? 10
        : 8;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _map.move(
          LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          zoom.toDouble(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RouteGeometry>(
    future: _geometry,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData) {
        return const Center(child: Text('Route map is unavailable.'));
      }
      final geometry = snapshot.data!;
      _fitRoute(geometry);
      return FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: geometry.origin,
          initialZoom: 12,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.smartrideug.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: geometry.points,
                color: AppTheme.orange,
                strokeWidth: 5,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              _marker(
                geometry.origin,
                Icons.trip_origin_rounded,
                AppTheme.success,
                'Origin',
              ),
              _marker(
                geometry.destination,
                Icons.flag_rounded,
                AppTheme.orange,
                'Destination',
              ),
              ...geometry.stops.map(
                (stop) => _marker(
                  stop.position,
                  Icons.location_on_rounded,
                  AppTheme.navy,
                  stop.name,
                ),
              ),
              ...widget.buses.map((bus) {
                final data = bus.data();
                final latitude = data['currentLatitude'] ?? data['latitude'];
                final longitude = data['currentLongitude'] ?? data['longitude'];
                if (latitude is! num || longitude is! num) return null;
                return _busMarker(
                  LatLng(latitude.toDouble(), longitude.toDouble()),
                  bus,
                );
              }).whereType<Marker>(),
              ...<Marker?>[
                if (widget.currentBus != null)
                  _currentBusMarker(widget.currentBus!),
              ].whereType<Marker>(),
              if (_passengerLocation != null)
                _marker(
                  _passengerLocation!,
                  Icons.person_pin_circle_rounded,
                  const Color(0xFF2878E8),
                  'Your location',
                ),
            ],
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      );
    },
  );

  Marker _marker(LatLng point, IconData icon, Color color, String label) =>
      Marker(
        point: point,
        width: 46,
        height: 46,
        child: Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      );

  Marker _busMarker(
    LatLng point,
    QueryDocumentSnapshot<Map<String, dynamic>> bus,
  ) {
    final label = bus.data()['busNumber']?.toString() ?? 'Bus';
    return Marker(
      point: point,
      width: 52,
      height: 52,
      child: Tooltip(
        message: 'Bus $label',
        child: GestureDetector(
          onTap: widget.onBusTap == null ? null : () => widget.onBusTap!(bus),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Marker? _currentBusMarker(Map<String, dynamic> bus) {
    final latitude = bus['currentLatitude'] ?? bus['latitude'];
    final longitude = bus['currentLongitude'] ?? bus['longitude'];
    if (latitude is! num || longitude is! num) return null;
    final label =
        bus['plateNumber']?.toString() ??
        bus['plate']?.toString() ??
        bus['busNumber']?.toString() ??
        'Bus';
    return Marker(
      point: LatLng(latitude.toDouble(), longitude.toDouble()),
      width: 52,
      height: 52,
      child: Tooltip(
        message: '$label • ${bus['status'] ?? 'on route'}',
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.orange,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}
