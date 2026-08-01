import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/route_details_page.dart';

<<<<<<< HEAD
=======
/// Finds active routes by destination and combines them with the live vehicle
/// feed. Both streams stay open, so the matching route and its buses update
/// without the passenger searching again.
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  static const routeName = '/destination';

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}
<<<<<<< HEAD

class _DestinationPageState extends State<DestinationPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(
      context,
    ).padding.bottom; // 🔥 Get system bottom padding

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Choose Destination'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search destination...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 16),

              // 🔥 Routes List (Expanded = takes all remaining space)
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('routes')
                      .where('active', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load routes',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final routes = snapshot.data!.docs;

                    final filteredRoutes = _searchQuery.isEmpty
                        ? routes
                        : routes.where((route) {
                            final data = route.data();
                            final name =
                                data['name']?.toString().toLowerCase() ?? '';
                            final origin =
                                data['origin']?.toString().toLowerCase() ?? '';
                            final destination =
                                data['destination']?.toString().toLowerCase() ??
                                '';
                            return name.contains(_searchQuery) ||
                                origin.contains(_searchQuery) ||
                                destination.contains(_searchQuery);
                          }).toList();

                    if (filteredRoutes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No active routes available'
                                  : 'No routes match "$_searchQuery"',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Check back later for new routes'
                                  : 'Try a different search term',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final routes = snapshot.data!.docs;

                // 🔥 Filter routes based on search query
                final filteredRoutes =
                    routes.where((route) {
                      final data = route.data();
                      if (data['active'] == false || data['disabled'] == true) {
                        return false;
                      }
                      return _searchQuery.isEmpty ||
                          _matchesDestination(data, _searchQuery);
                    }).toList()..sort(
                      (a, b) =>
                          _matchRank(a.data()).compareTo(_matchRank(b.data())),
                    );

                if (filteredRoutes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No routes available'
                              : 'No routes travel to "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Check back later for new routes'
                              : 'Try a nearby destination, route name, or code',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    final data = route.data();
                    final title = data['name']?.toString() ?? route.id;
                    final subtitle =
                        data['subtitle']?.toString() ??
                        [
                          data['origin'],
                          data['destination'],
                        ].whereType<String>().join(' → ');
                    final distance = data['distance']?.toString() ?? 'Unknown';
                    final duration = data['duration']?.toString() ?? 'Unknown';
                    return _RouteCard(
                      routeId: route.id,
                      title: title,
                      subtitle: subtitle,
                      distance: distance,
                      duration: duration,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RouteDetailsPage(routeId: route.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // 🔥 Info Card
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Live updates: Bus locations and seat availability are updated in real time.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 🔥 FIX: Added bottom padding to prevent overflow
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding + 8),
                child: Card(
                  elevation: 0,
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Live updates: Bus locations and seat availability are updated in real time.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
=======

class _DestinationPageState extends State<DestinationPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose destination'), elevation: 0),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
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
                  final matchingRoutes = routeSnapshot.data!.docs
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
                      return ListView(
                        children: [
                          Text(
                            _query.isEmpty
                                ? 'Available routes'
                                : 'Routes to ${_search.text.trim()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...matchingRoutes.map(
                            (route) => _RouteCard(
                              route: route,
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
                                    Icons.sync_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Routes and buses update automatically as drivers go online or move.',
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
              ),
            ),
          ],
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
    required this.buses,
    required this.onTap,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> route;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> buses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
<<<<<<< HEAD
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    title.split(' ').last,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🔥 Route Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: busesAvailable > 0
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$busesAvailable buses',
                      style: TextStyle(
                        color: busesAvailable > 0 ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                ],
              ),
              const SizedBox(height: 14),
              Text(
                buses.isEmpty
                    ? 'No buses are online on this route yet'
                    : '${buses.length} live ${buses.length == 1 ? 'bus' : 'buses'} on this route',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
        );
      },
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
