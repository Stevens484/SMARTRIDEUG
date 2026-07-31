import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

class RouteDetailsPage extends StatefulWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _routeFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _busesStream;

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
    _busesStream = FirebaseFirestore.instance
        .collection('buses')
        .where('routeId', isEqualTo: widget.routeId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Route Details'), elevation: 0),
    body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _routeFuture,
      builder: (context, routeSnapshot) {
        if (routeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (routeSnapshot.hasError || !routeSnapshot.hasData) {
          return _loadError();
        }
        final route = routeSnapshot.data!.data();
        if (route == null) return _loadError(message: 'Route not found.');
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _busesStream,
          builder: (context, busesSnapshot) {
            final buses = (busesSnapshot.data?.docs ?? const [])
                .where((bus) => _isAvailable(bus.data()))
                .toList();
            return _routeContent(route, buses);
          },
        );
      },
    ),
  );

  Widget _loadError({String message = 'Failed to load route.'}) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => setState(_loadData),
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _routeContent(
    Map<String, dynamic> route,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> buses,
  ) {
    final origin = route['origin']?.toString() ?? 'Origin not specified';
    final destination =
        route['destination']?.toString() ?? 'Destination not specified';
    final routeName = route['name']?.toString() ?? '$origin - $destination';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _endpointRow(
                    icon: Icons.location_on,
                    color: Colors.green,
                    label: origin,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: Icon(Icons.more_vert, color: Colors.grey),
                  ),
                  _endpointRow(
                    icon: Icons.flag,
                    color: Colors.red,
                    label: destination,
                  ),
                  const Divider(height: 24),
                  Text(
                    '${buses.length} active ${buses.length == 1 ? 'bus' : 'buses'}',
                    style: TextStyle(
                      color: buses.isEmpty ? Colors.grey : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 230,
              child: _RouteMapPreview(
                routeId: widget.routeId,
                route: route,
                originName: origin,
                destinationName: destination,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            buses.isEmpty ? 'Active Buses' : 'Active Buses on Route',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (buses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No active buses on this route yet.')),
            )
          else
            ...buses.map(_busTile),
        ],
      ),
    );
  }

  Widget _endpointRow({
    required IconData icon,
    required Color color,
    required String label,
  }) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  Widget _busTile(QueryDocumentSnapshot<Map<String, dynamic>> bus) {
    final data = bus.data();
    final number =
        data['registrationNumber']?.toString() ??
        data['busNumber']?.toString() ??
        bus.id;
    final status = data['status']?.toString() ?? 'Online';
    final seats = data['availableSeats']?.toString() ?? 'N/A';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_bus, color: Colors.green),
        title: Text('Bus $number'),
        subtitle: Text('$status • $seats seats available'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BusDetailsPage(
              busId: bus.id,
              routeId: widget.routeId,
              number: number,
            ),
          ),
        ),
      ),
    );
  }

  bool _isAvailable(Map<String, dynamic> bus) {
    const activeStatuses = {
      'active',
      'online',
      'moving',
      'approaching_stop',
      'stopped',
    };
    return bus['disabled'] != true &&
        activeStatuses.contains(
          bus['status']?.toString().toLowerCase() ?? 'active',
        );
  }
}

class _RouteMapPreview extends StatefulWidget {
  const _RouteMapPreview({
    required this.routeId,
    required this.route,
    required this.originName,
    required this.destinationName,
  });

  final String routeId;
  final Map<String, dynamic> route;
  final String originName;
  final String destinationName;

  @override
  State<_RouteMapPreview> createState() => _RouteMapPreviewState();
}

class _RouteMapPreviewState extends State<_RouteMapPreview> {
  final _geometryService = RouteGeometryService();
  late Future<RouteGeometry> _geometry;
  late String _signature;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void didUpdateWidget(covariant _RouteMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _routeSignature(widget);
    if (nextSignature != _signature) {
      _geometryService.invalidate(widget.routeId);
      _startLoading();
    }
  }

  void _startLoading() {
    _signature = _routeSignature(widget);
    _geometry = _geometryService.resolve(
      routeId: widget.routeId,
      route: widget.route,
    );
  }

  String _routeSignature(_RouteMapPreview route) =>
      '${route.routeId}:${route.route['updatedAt']}';

  @override
  Widget build(BuildContext context) => FutureBuilder<RouteGeometry>(
    future: _geometry,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Route map is unavailable. Add ordered stops or valid endpoints.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      final geometry = snapshot.data!;
      return FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            (geometry.origin.latitude + geometry.destination.latitude) / 2,
            (geometry.origin.longitude + geometry.destination.longitude) / 2,
          ),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.smartrideug',
          ),
          RichAttributionWidget(
            attributions: const [TextSourceAttribution('© OpenStreetMap')],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: geometry.points,
                color: const Color(0xFF2563EB),
                strokeWidth: 5,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: geometry.origin,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: widget.originName,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
              ),
              Marker(
                point: geometry.destination,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: widget.destinationName,
                  child: const Icon(Icons.flag, color: Colors.red, size: 30),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
