import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_map/flutter_map.dart'; // 🔥 REPLACES google_maps_flutter
import 'package:latlong2/latlong.dart'; // 🔥 FOR MAP COORDINATES
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/services/bus_eta_service.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/features/home/seat_layout_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class BusDetailsPage extends StatelessWidget {
  final String busId;
  final String routeId;
  final String number;
  final String? routeId;

  const BusDetailsPage({
    super.key,
    required this.busId,
<<<<<<< HEAD
    required this.routeId,
    required this.number,
=======
    required this.number,
    this.routeId,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget assignedRoute(Map<String, dynamic> busData) {
      final assignedRouteId =
          busData['routeId']?.toString() ??
          busData['currentRoute']?.toString() ??
          routeId;
      if (assignedRouteId == null || assignedRouteId.isEmpty) {
        return const Text('No route assigned yet.');
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(assignedRouteId)
            .snapshots(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          if (route == null) {
            return Text(
              busData['routeName']?.toString() ?? 'Assigned route unavailable',
            );
          }
          final routeName = route['name']?.toString() ?? 'Assigned route';
          final origin = route['origin']?.toString() ?? 'Unknown origin';
          final destination =
              route['destination']?.toString() ?? 'Unknown destination';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routeName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text('$origin → $destination'),
            ],
          );
        },
      );
    }

    Widget driverDetails(Map<String, dynamic> busData) {
      final driverId = busData['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) {
        return const Text('No driver is assigned to this bus yet.');
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(driverId)
            .snapshots(),
        builder: (context, snapshot) {
          final driver = snapshot.data?.data();
          if (driver == null) return const Text('Driver profile unavailable.');
          final name =
              driver['displayName']?.toString() ??
              driver['name']?.toString() ??
              'Assigned driver';
          final email = driver['email']?.toString();
          final employeeId = driver['employeeId']?.toString();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (email != null && email.isNotEmpty) Text(email),
              if (employeeId != null && employeeId.isNotEmpty)
                Text('Driver ID: $employeeId'),
            ],
          );
        },
      );
    }

    Widget detailsColumn(Map<String, dynamic> busData) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 36,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUS ${busData['busNumber']?.toString() ?? number}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (busData['plateNumber'] ?? busData['plate'])
                                ?.toString() ??
                            'Plate not available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          (busData['status']?.toString() ?? 'On Route')
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: busData['status'] == 'offline'
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                assignedRoute(busData),
                const SizedBox(height: 12),
                const Text(
                  'Driver',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                driverDetails(busData),
                const SizedBox(height: 12),
                const Text(
                  'Pickup stops & live arrivals',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _RoutePickupStops(routeId: routeId, busData: busData),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final assignedRouteId =
                  busData['routeId']?.toString() ??
                  busData['currentRoute']?.toString() ??
                  routeId;
              if (assignedRouteId == null || assignedRouteId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This bus has no route assignment yet.'),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeatLayoutPage(
                    busId: busId,
<<<<<<< HEAD
                    routeId: routeId,
                    busNumber: number,
=======
                    busNumber: busData['busNumber']?.toString() ?? number,
                    routeId: assignedRouteId,
                    totalSeats: (busData['totalSeats'] as num?)?.toInt() ?? 1,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                  ),
                ),
              );
            },
            child: const Text('View Seat Layout'),
          ),
        ),
      ],
    );

    // 🔥 NEW: Map preview using FlutterMap (free, no API keys)
    Widget mapPreview(Map<String, dynamic> busData) {
<<<<<<< HEAD
      // Get pickup location from bus data, with fallback
      final pickupLat = (busData['latitude'] as num?)?.toDouble() ?? 0.3392;
      final pickupLng = (busData['longitude'] as num?)?.toDouble() ?? 32.5736;
      final destLat = (busData['destinationLat'] as num?)?.toDouble() ?? 0.3516;
      final destLng =
          (busData['destinationLng'] as num?)?.toDouble() ?? 32.6112;

      final pickup = LatLng(pickupLat, pickupLng);
      final destination = LatLng(destLat, destLng);

      return Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(initialCenter: pickup, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smartrideug',
              ),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, destination],
                    color: const Color(0xFF2563EB),
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    child: const Tooltip(
                      message: 'Pickup',
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                  ),
                  Marker(
                    point: destination,
                    width: 40,
                    height: 40,
                    child: const Tooltip(
                      message: 'Destination',
                      child: Icon(Icons.flag, color: Colors.red, size: 30),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
=======
      final activeRouteId =
          busData['routeId']?.toString() ?? busData['currentRoute']?.toString();
      final resolvedRouteId = activeRouteId ?? routeId;
      if (resolvedRouteId == null || resolvedRouteId.isEmpty) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(resolvedRouteId)
            .snapshots(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          if (route == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: RouteMapPanel(
              routeId: resolvedRouteId,
              route: route,
              currentBus: busData,
            ),
          );
        },
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .snapshots(),
          builder: (context, snapshot) {
            final busNumber = snapshot.data?.data()?['busNumber']?.toString();
            return Text(
              'Bus ${busNumber?.isNotEmpty == true ? busNumber : number}',
            );
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnapshot) {
            if (!busSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final savedBus = busSnapshot.data!.data() ?? <String, dynamic>{};
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('busLocations')
                  .doc(busId)
                  .snapshots(),
              builder: (context, locationSnapshot) {
                final busData = <String, dynamic>{
                  ...savedBus,
                  ...?locationSnapshot.data?.data(),
                };
                final busNumber = busData['busNumber']?.toString() ?? number;
                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: detailsColumn({
                                ...busData,
                                'busNumber': busNumber,
                              }),
                            ),
                          ),
                          if ((busData['routeId'] ??
                                  busData['currentRoute'] ??
                                  routeId) !=
                              null)
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: mapPreview(busData),
                              ),
                            ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            detailsColumn({...busData, 'busNumber': busNumber}),
                            if ((busData['routeId'] ??
                                    busData['currentRoute'] ??
                                    routeId) !=
                                null) ...[
                              const SizedBox(height: 16),
                              SizedBox(height: 240, child: mapPreview(busData)),
                            ],
                          ],
                        ),
<<<<<<< HEAD
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: mapPreview(busData),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        detailsColumn(busData),
                        const SizedBox(height: 16),
                        mapPreview(busData),
                      ],
                    ),
                  );
=======
                      );
              },
            );
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          },
        ),
      ),
    );
  }
}

class _AssignedDriver extends StatelessWidget {
  const _AssignedDriver({this.name, this.driverId});

  final String? name;
  final String? driverId;

  @override
  Widget build(BuildContext context) {
    final driverName = name?.trim() ?? '';
    if (driverName.isNotEmpty) return Text(driverName);

    // Driver profile documents may contain private account information, so the
    // passenger screen intentionally uses the public name snapshot on the bus.
    // This fallback covers assignments created before that snapshot existed.
    return Text(
      (driverId?.trim().isNotEmpty ?? false)
          ? 'Driver assigned — details are being updated.'
          : 'No driver assigned yet.',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _RoutePickupStops extends StatelessWidget {
  const _RoutePickupStops({required this.routeId, required this.busData});

  final String routeId;
  final Map<String, dynamic> busData;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .collection('stops')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Pickup stops could not be loaded.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final stops = snapshot.data!.docs.toList()
            ..sort(
              (left, right) =>
                  ((left.data()['order'] as num?)?.toInt() ?? 999999).compareTo(
                    (right.data()['order'] as num?)?.toInt() ?? 999999,
                  ),
            );
          final etaStops = stops.map((stop) {
            final data = stop.data();
            final latitude = data['latitude'];
            final longitude = data['longitude'];
            return EtaStop(
              id: stop.id,
              name: data['name']?.toString().trim().isNotEmpty == true
                  ? data['name'].toString().trim()
                  : 'Pickup stop',
              location: latitude is num && longitude is num
                  ? LatLng(latitude.toDouble(), longitude.toDouble())
                  : null,
            );
          }).toList();
          if (etaStops.isEmpty) {
            return Text(
              'No pickup stops have been configured for this route.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }
          final latitude = busData['latitude'];
          final longitude = busData['longitude'];
          final location = busData['location'];
          final busLocation = latitude is num && longitude is num
              ? LatLng(latitude.toDouble(), longitude.toDouble())
              : location is GeoPoint
              ? LatLng(location.latitude, location.longitude)
              : null;
          final speed = busData['speedKph'] ?? busData['speed'];
          final etas = const BusEtaService().estimate(
            busLocation: busLocation,
            stops: etaStops,
            speedKph: speed is num
                ? speed
                : num.tryParse(speed?.toString() ?? ''),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  busLocation == null
                      ? 'Waiting for the bus location to calculate arrivals.'
                      : 'Live estimates update as the bus moves.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (var index = 0; index < etas.length; index++)
                _StopEtaRow(index: index, eta: etas[index]),
            ],
          );
        },
      );
}

class _StopEtaRow extends StatelessWidget {
  const _StopEtaRow({required this.index, required this.eta});

  final int index;
  final StopEta eta;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (eta.state) {
      StopEtaState.arriving => ('Arriving now', AppTheme.success),
      StopEtaState.upcoming => ('${eta.minutes ?? 0} min', AppTheme.primary),
      StopEtaState.passed => ('Passed', AppTheme.grey500),
      StopEtaState.unavailable => ('ETA unavailable', AppTheme.grey500),
    };
    final time = eta.arrivalTime == null
        ? null
        : TimeOfDay.fromDateTime(eta.arrivalTime!).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: eta.state == StopEtaState.arriving
            ? const Color(0xFFE7F5ED)
            : AppTheme.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              eta.stop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (time != null && eta.state == StopEtaState.upcoming)
                Text(
                  time,
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusRouteMapPreview extends StatefulWidget {
  const _BusRouteMapPreview({required this.routeId, required this.busData});

  final String routeId;
  final Map<String, dynamic> busData;

  @override
  State<_BusRouteMapPreview> createState() => _BusRouteMapPreviewState();
}

class _BusRouteMapPreviewState extends State<_BusRouteMapPreview> {
  final _geometryService = RouteGeometryService();
  late Future<RouteGeometry> _geometry;

  @override
  void initState() {
    super.initState();
    _geometry = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeId)
        .get()
        .then(
          (route) => _geometryService.resolve(
            routeId: widget.routeId,
            route: route.data() ?? const <String, dynamic>{},
          ),
        );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RouteGeometry>(
    future: _geometry,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 240,
          child: Center(child: Text('Route map is unavailable.')),
        );
      }
      final geometry = snapshot.data!;
      final latitude = widget.busData['latitude'];
      final longitude = widget.busData['longitude'];
      final busPosition = latitude is num && longitude is num
          ? LatLng(latitude.toDouble(), longitude.toDouble())
          : null;
      return SizedBox(
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: busPosition ?? geometry.origin,
              initialZoom: 14,
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
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                  Marker(
                    point: geometry.destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag, color: Colors.red, size: 30),
                  ),
                  if (busPosition != null)
                    Marker(
                      point: busPosition,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.green,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
