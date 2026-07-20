import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/route_details_page.dart';

class DestinationPage extends StatelessWidget {
  const DestinationPage({super.key});

  static const routeName = '/destination';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Destination'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('routes')
                      .where('active', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final routes = snapshot.data!.docs;
                    if (routes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No active routes are available at the moment.',
                        ),
                      );
                    }

                    return Column(
                      children: [
                        const Text(
                          'Suggested Routes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...routes.map((route) {
                          final data = route.data();
                          final title = data['name']?.toString() ?? route.id;
                          final subtitle =
                              data['subtitle']?.toString() ??
                              [
                                data['origin'],
                                data['destination'],
                              ].whereType<String>().join(' → ');
                          final distance =
                              data['distance']?.toString() ?? 'Unknown';
                          final duration =
                              data['duration']?.toString() ?? 'Unknown';
                          final available =
                              data['activeBuses']?.toString() ??
                              data['busCount']?.toString() ??
                              '0';
                          return _RouteCard(
                            title: title,
                            subtitle: subtitle,
                            distance: distance,
                            duration: duration,
                            busesAvailable: int.tryParse(available) ?? 0,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RouteDetailsPage(routeId: route.id),
                                ),
                              );
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Live updates: Bus locations and seat availability are updated in real time.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;
  final String duration;
  final int busesAvailable;
  final VoidCallback onTap;

  const _RouteCard({
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.duration,
    required this.busesAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    title.split(' ').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(distance, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(duration, style: const TextStyle(fontSize: 12)),
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(31),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$busesAvailable buses',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
