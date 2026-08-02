import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

/// The selected route, its ordered stops, and the buses currently serving it.
class RouteDetailsPage extends StatelessWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  static const routeName = '/route_details';
  final String routeId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .snapshots(),
      builder: (context, routeSnapshot) {
        if (!routeSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final document = routeSnapshot.data!;
        if (!document.exists || document.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route details')),
            body: const Center(child: Text('Route not found.')),
          );
        }
        final route = document.data()!;
        final title = route['name']?.toString() ?? routeId;
        final subtitle =
            route['subtitle']?.toString() ??
            [
              route['origin'],
              route['destination'],
            ].whereType<String>().join(' → ');

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('busLocations')
              .where('routeId', isEqualTo: routeId)
              .snapshots(),
          builder: (context, busSnapshot) {
            // A bus can remain assigned to a route while it is offline. Only
            // show vehicles that are presently serving the selected route.
            final buses = (busSnapshot.data?.docs ?? const [])
                .where((bus) => _isActive(bus.data()))
                .toList();
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _RouteHeading(title: title, subtitle: subtitle),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 330,
                      child: RouteMapPanel(
                        routeId: routeId,
                        route: route,
                        buses: buses,
                        onBusTap: (bus) => _showBusSummary(
                          context,
                          routeId: routeId,
                          document: bus,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Active buses on route',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (buses.isEmpty)
                    const _EmptyBuses()
                  else
                    ...buses.map(
                      (bus) => _BusCard(
                        document: bus,
                        onTap: () => _showBusSummary(
                          context,
                          routeId: routeId,
                          document: bus,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static bool _isActive(Map<String, dynamic> bus) {
    const activeStatuses = {
      'active',
      'online',
      'moving',
      'approaching_stop',
      'on_route',
      'on route',
    };
    return activeStatuses.contains(
      bus['status']?.toString().trim().toLowerCase(),
    );
  }

  void _showBusSummary(
    BuildContext context, {
    required String routeId,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BusSummarySheet(routeId: routeId, document: document),
    );
  }
}

class _RouteHeading extends StatelessWidget {
  const _RouteHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.grey500)),
          ],
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppTheme.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live arrivals update as buses move along this route.',
                  style: TextStyle(color: AppTheme.grey700),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BusCard extends StatelessWidget {
  const _BusCard({
    required this.document,
    required this.onTap,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bus = document.data();
    final number = bus['busNumber']?.toString() ?? document.id;
    final seats = bus['availableSeats']?.toString() ?? '—';
    final eta =
        bus['eta']?.toString() ??
        bus['nextStopEta']?.toString() ??
        'ETA unavailable';
    final status = bus['status']?.toString() ?? 'On route';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: AppTheme.orange,
          ),
        ),
        title: Text(
          'Bus $number',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$eta • $seats seats available'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              status,
              style: const TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.grey500),
          ],
        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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

class _BusSummarySheet extends StatelessWidget {
  const _BusSummarySheet({required this.routeId, required this.document});

  final String routeId;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('buses').doc(document.id).snapshots(),
    builder: (context, snapshot) {
      // busLocations supplies the live coordinates/status; the bus document
      // holds the booking data such as the bus number and open seats.
      final bus = <String, dynamic>{
        ...document.data(),
        ...?snapshot.data?.data(),
      };
      return _content(context, bus);
    },
  );

  Widget _content(BuildContext context, Map<String, dynamic> bus) {
    final number = bus['busNumber']?.toString() ?? document.id;
    final seats = bus['availableSeats']?.toString() ?? 'Seat availability pending';
    final eta =
        bus['eta']?.toString() ??
        bus['nextStopEta']?.toString() ??
        'Live ETA pending';
    final status = bus['status']?.toString() ?? 'Online';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus $number',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _summaryRow(Icons.circle, 'Status: $status'),
            _summaryRow(Icons.schedule_outlined, eta),
            _summaryRow(Icons.event_seat_outlined, '$seats seats available'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_bus_rounded),
                label: const Text('View bus and choose seats'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusDetailsPage(
                        busId: document.id,
                        number: number,
                        routeId: routeId,
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
  }

  Widget _summaryRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.grey500),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _EmptyBuses extends StatelessWidget {
  const _EmptyBuses();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.directions_bus_outlined, color: AppTheme.grey500),
          SizedBox(width: 12),
          Expanded(
            child: Text('No live buses are available for this route yet.'),
          ),
        ],
      ),
    ),
  );
}
