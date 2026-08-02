import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartrideug/features/home/route_details_page.dart';

/// Finds active routes by destination and combines them with the live vehicle
/// feed. Both streams stay open, so the matching route and its buses update
/// without the passenger searching again.
class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  static const routeName = '/destination';

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  final _search = TextEditingController();
  String _query = '';
  Position? _position;
  bool _locating = true;

  static const _nearbyRouteMetres = 2500.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) setState(() => _position = position);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Choose destination'),
      elevation: 0,
      actions: [
        IconButton(
          tooltip: 'Update location',
          icon: const Icon(Icons.my_location_outlined),
          onPressed: _locating
              ? null
              : () {
                  setState(() => _locating = true);
                  _loadCurrentLocation();
                },
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.viewInsetsOf(context).bottom > 0 &&
                  MediaQuery.orientationOf(context) == Orientation.landscape
              ? 4
              : 16,
          16,
          MediaQuery.viewInsetsOf(context).bottom > 0 &&
                  MediaQuery.orientationOf(context) == Orientation.landscape
              ? 4
              : 16,
        ),
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                hintText: 'Type a destination, e.g. Ntinda',
              ),
            ),
            SizedBox(
              height:
                  MediaQuery.viewInsetsOf(context).bottom > 0 &&
                      MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 4
                  : 16,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('routes')
                    .where('active', isEqualTo: true)
                    .snapshots(),
                builder: (context, routeSnapshot) {
                  if (routeSnapshot.hasError) {
                    return _message('Routes could not be loaded.');
                  }
                  if (!routeSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final routeDocuments = routeSnapshot.data?.docs;
                  if (routeDocuments == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final matchingRoutes = routeDocuments
                      .where((route) => _matchesDestination(route.data()))
                      .toList();
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('busLocations')
                        .where(
                          'status',
                          whereIn: const [
                            'online',
                            'moving',
                            'approaching_stop',
                            'active',
                            'on_route',
                          ],
                        )
                        .snapshots(),
                    builder: (context, busSnapshot) {
                      if (busSnapshot.hasError) {
                        return _message('Live buses could not be loaded.');
                      }
                      final buses = busSnapshot.data?.docs ?? const [];
                      if (matchingRoutes.isEmpty) {
                        return _message(
                          _query.isEmpty
                              ? 'No active routes are available at the moment.'
                              : 'No active route goes to “${_search.text.trim()}”.',
                        );
                      }
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('stops')
                            .snapshots(),
                        builder: (context, stopSnapshot) {
                          if (stopSnapshot.hasError) {
                            return _message(
                              'Route points could not be loaded.',
                            );
                          }
                          if (!stopSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final stopDocuments = stopSnapshot.data?.docs;
                          if (stopDocuments == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final distances = _nearbyRouteDistances(
                            matchingRoutes,
                            stopDocuments,
                          );
                          final nearbyRoutes = [...matchingRoutes];
                          if (_position != null) {
                            nearbyRoutes.removeWhere(
                              (route) => !distances.containsKey(route.id),
                            );
                            nearbyRoutes.sort(
                              (a, b) => (distances[a.id] ?? double.infinity)
                                  .compareTo(
                                    distances[b.id] ?? double.infinity,
                                  ),
                            );
                          }
                          if (_position != null && nearbyRoutes.isEmpty) {
                            return _message(
                              'No route passes within 2.5 km of your current location.',
                            );
                          }
                          return ListView(
                            children: [
                              Text(
                                _position == null
                                    ? _locating
                                          ? 'Finding routes near you…'
                                          : _query.isEmpty
                                          ? 'Available routes'
                                          : 'Routes to ${_search.text.trim()}'
                                    : _query.isEmpty
                                    ? 'Routes near you'
                                    : 'Routes near you to ${_search.text.trim()}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ...nearbyRoutes.map(
                                (route) => _RouteCard(
                                  route: route,
                                  distanceMetres: distances[route.id],
                                  buses: buses
                                      .where(
                                        (bus) =>
                                            bus.data()['routeId']?.toString() ==
                                            route.id,
                                      )
                                      .toList(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RouteDetailsPage(routeId: route.id),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.my_location_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _position == null
                                              ? 'Allow location access to see routes that pass near you.'
                                              : 'Showing routes with a stop within 2.5 km of you.',
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    ),
  );

  bool _matchesDestination(Map<String, dynamic> route) {
    if (_query.isEmpty) return true;
    final destination = route['destination']?.toString().toLowerCase() ?? '';
    // Destination is intentionally the primary match: typing a place leaves
    // only routes that go there, rather than unrelated routes that merely pass it.
    return destination.contains(_query);
  }

  Map<String, double> _nearbyRouteDistances(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> routes,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stops,
  ) {
    final position = _position;
    if (position == null) return const {};
    final routeIds = routes.map((route) => route.id).toSet();
    final distances = <String, double>{};
    for (final stop in stops) {
      final data = stop.data();
      final routeId = data['routeId']?.toString();
      final latitude = data['latitude'] ?? data['lat'];
      final longitude = data['longitude'] ?? data['lng'];
      if (routeId == null ||
          !routeIds.contains(routeId) ||
          latitude is! num ||
          longitude is! num) {
        continue;
      }
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      );
      if (distance > _nearbyRouteMetres) continue;
      final previous = distances[routeId];
      if (previous == null || distance < previous) {
        distances[routeId] = distance;
      }
    }
    return distances;
  }

  Widget _message(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    this.distanceMetres,
    required this.buses,
    required this.onTap,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> route;
  final double? distanceMetres;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> buses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = route.data();
    final destination =
        data['destination']?.toString() ?? 'Destination unavailable';
    final origin = data['origin']?.toString() ?? 'Origin unavailable';
    final title = data['name']?.toString() ?? '$origin → $destination';
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.route_rounded, color: scheme.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$origin → $destination',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                buses.isEmpty
                    ? 'No buses are online on this route yet'
                    : '${buses.length} live ${buses.length == 1 ? 'bus' : 'buses'} on this route',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (distanceMetres != null) ...[
                const SizedBox(height: 5),
                Text(
                  distanceMetres! < 1000
                      ? '${distanceMetres!.round()} m from your nearest route point'
                      : '${(distanceMetres! / 1000).toStringAsFixed(1)} km from your nearest route point',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (buses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: buses
                      .map((bus) => _LiveBusChip(bus: bus.data()))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBusChip extends StatelessWidget {
  const _LiveBusChip({required this.bus});
  final Map<String, dynamic> bus;

  @override
  Widget build(BuildContext context) {
    final identifier = bus['plateNumber']?.toString().isNotEmpty == true
        ? bus['plateNumber'].toString()
        : bus['busNumber']?.toString() ?? 'Bus';
    final seats = bus['availableSeats'] as num?;
    final status = bus['status']?.toString() ?? 'online';
    return Chip(
      avatar: const Icon(Icons.directions_bus_rounded, size: 18),
      label: Text(
        '$identifier • ${seats == null ? 'seats updating' : '${seats.toInt()} seats'} • $status',
      ),
    );
  }
}
