import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      isScrollControlled: true,
      useSafeArea: true,
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
  const _BusCard({required this.document, required this.onTap});
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
      ),
    );
  }
}

class _BusSummarySheet extends StatelessWidget {
  const _BusSummarySheet({required this.routeId, required this.document});

  final String routeId;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .doc(document.id)
            .snapshots(),
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
    final seats =
        bus['availableSeats']?.toString() ?? 'Seat availability pending';
    final eta =
        bus['eta']?.toString() ??
        bus['nextStopEta']?.toString() ??
        'Live ETA pending';
    final status = bus['status']?.toString() ?? 'Online';
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bus $number', style: Theme.of(context).textTheme.titleLarge),
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
