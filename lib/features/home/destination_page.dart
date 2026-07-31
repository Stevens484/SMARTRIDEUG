import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/route_details_page.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  static const routeName = '/destination';

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Choose Destination'), elevation: 0),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            // 🔥 Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Where are you going? (e.g. Makerere)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 16),

            // 🔥 Routes List
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
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
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesDestination(Map<String, dynamic> data, String query) {
    final aliases = data['destinationAliases'];
    final searchable =
        [data['destination'], if (aliases is Iterable) ...aliases]
            .map((value) => value.toString().toLowerCase())
            .where((value) => value.isNotEmpty);
    return searchable.any((value) => value.contains(query));
  }

  int _matchRank(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return 0;
    final destination = data['destination']?.toString().toLowerCase() ?? '';
    if (destination == _searchQuery) return 0;
    if (destination.startsWith(_searchQuery)) return 1;
    return 2;
  }
}

// ============================================================
// 🔥 ROUTE CARD
// ============================================================
class _RouteCard extends StatelessWidget {
  final String routeId;
  final String title;
  final String subtitle;
  final String distance;
  final String duration;
  final VoidCallback onTap;

  const _RouteCard({
    required this.routeId,
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buses')
          .where('routeId', isEqualTo: routeId)
          .snapshots(),
      builder: (context, snapshot) {
        const availableStatuses = {
          'active',
          'online',
          'moving',
          'approaching_stop',
          'stopped',
        };
        final busesAvailable = snapshot.hasData
            ? snapshot.data!.docs.where((bus) {
                final data = bus.data();
                final status =
                    data['status']?.toString().toLowerCase() ?? 'active';
                return data['disabled'] != true &&
                    availableStatuses.contains(status);
              }).length
            : 0;

        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 Route Icon/Number
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
                  ),

                  // 🔥 Bus Count & Arrow
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
                            color: busesAvailable > 0
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
