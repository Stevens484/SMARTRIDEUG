import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

class RouteDetailsPage extends StatelessWidget {
  final String routeId;

  const RouteDetailsPage({super.key, required this.routeId});

  static const routeName = '/route_details';

  LatLng _coordinateFrom(
    Map<String, dynamic> data,
    String latKey,
    String lngKey,
    LatLng fallback,
  ) {
    final lat = (data[latKey] as num?)?.toDouble();
    final lng = (data[lngKey] as num?)?.toDouble();
    return lat == null || lng == null ? fallback : LatLng(lat, lng);
  }

  List<LatLng> _routePointsFrom(
    Map<String, dynamic> data,
    LatLng origin,
    LatLng destination,
  ) {
    final path = data['path'] as List<dynamic>?;
    if (path == null) {
      return [origin, destination];
    }

    final points = path
        .whereType<Map<String, dynamic>>()
        .map((point) {
          final lat = (point['latitude'] as num?)?.toDouble();
          final lng = (point['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          return LatLng(lat, lng);
        })
        .whereType<LatLng>()
        .toList();

    return points.length >= 2 ? points : [origin, destination];
  }

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

        final routeDoc = routeSnapshot.data!;
        if (!routeDoc.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route details')),
            body: const Center(child: Text('Route not found.')),
          );
        }

        final routeData = routeDoc.data()!;
        final title = routeData['name']?.toString() ?? routeId;
        final subtitle =
            routeData['subtitle']?.toString() ??
            [
              routeData['origin'],
              routeData['destination'],
            ].whereType<String>().join(' → ');
        final origin = _coordinateFrom(
          routeData,
          'originLat',
          'originLng',
          const LatLng(0.3392, 32.5736),
        );
        final destination = _coordinateFrom(
          routeData,
          'destinationLat',
          'destinationLng',
          const LatLng(0.3516, 32.6112),
        );
        final routePoints = _routePointsFrom(routeData, origin, destination);
        final center = LatLng(
          (origin.latitude + destination.latitude) / 2,
          (origin.longitude + destination.longitude) / 2,
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('busLocations')
              .where('routeId', isEqualTo: routeId)
              .snapshots(),
          builder: (context, busSnapshot) {
            final buses = busSnapshot.data?.docs ?? const [];
            final busMarkers = buses
                .map((doc) {
                  final data = doc.data();
                  final lat = (data['latitude'] as num?)?.toDouble();
                  final lng = (data['longitude'] as num?)?.toDouble();
                  if (lat == null || lng == null) return null;
                  return Marker(
                    markerId: MarkerId(doc.id),
                    position: LatLng(lat, lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: InfoWindow(
                      title: data['busNumber']?.toString() ?? doc.id,
                      snippet:
                          '${data['availableSeats']?.toString() ?? 'unknown'} seats available',
                    ),
                  );
                })
                .whereType<Marker>()
                .toSet();

            final routeMarkers = {
              Marker(
                markerId: const MarkerId('pickup'),
                position: origin,
                infoWindow: InfoWindow(
                  title: 'Pickup: ${routeData['origin'] ?? 'Start'}',
                ),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: destination,
                infoWindow: InfoWindow(
                  title: 'Drop-off: ${routeData['destination'] ?? 'End'}',
                ),
              ),
            };

            final markers = {...routeMarkers, ...busMarkers};
            final busCount = buses.length;

            return Scaffold(
              appBar: AppBar(title: Text(title), elevation: 0),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 280,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: center,
                          zoom: 12,
                        ),
                        markers: markers,
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: routePoints,
                            color: Theme.of(context).colorScheme.primary,
                            width: 5,
                          ),
                        },
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            routeData['description']?.toString() ??
                                'Live route updates from SmartRide.',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$busCount buses available',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                routeData['duration']?.toString() ??
                                    'Duration unknown',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (buses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No live buses are available for this route.',
                              ),
                            )
                          else
                            Column(
                              children: buses.map((doc) {
                                final data = doc.data();
                                final busNumber =
                                    data['busNumber']?.toString() ?? doc.id;
                                final seatInfo =
                                    data['availableSeats']?.toString() ??
                                    'Unknown';
                                final eta = data['eta']?.toString() ?? 'TBD';
                                final away =
                                    data['distanceToDestination']?.toString() ??
                                    'TBD';
                                final status =
                                    data['status']?.toString() ?? 'On route';
                                return _BusCard(
                                  busId: doc.id,
                                  routeId: routeId,
                                  number: busNumber,
                                  plate: data['plate']?.toString() ?? 'Unknown',
                                  eta: eta,
                                  seats: '$seatInfo seats',
                                  away: away,
                                  status: status,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BusCard extends StatefulWidget {
  final String busId;
  final String routeId;
  final String number;
  final String plate;
  final String eta;
  final String seats;
  final String away;
  final String status;

  const _BusCard({
    required this.busId,
    required this.routeId,
    required this.number,
    required this.plate,
    required this.eta,
    required this.seats,
    required this.away,
    required this.status,
  });

  @override
  State<_BusCard> createState() => _BusCardState();
}

class _BusCardState extends State<_BusCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.status.toLowerCase().contains('full')
        ? Colors.red
        : widget.status.toLowerCase().contains('pending')
        ? Colors.orange
        : Colors.green;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BusDetailsPage(
                    busId: widget.busId,
                    routeId: widget.routeId,
                    number: widget.number,
                  ),
                ),
              );
            },
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.number,
                  style: TextStyle(fontWeight: FontWeight.bold, color: bg),
                ),
              ),
            ),
            title: Text('BUS ${widget.number}'),
            subtitle: Text('${widget.eta} • ${widget.seats} • ${widget.away}'),
            trailing: SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Chip(
                      label: Text(
                        widget.status,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      backgroundColor: bg,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plate: ${widget.plate}'),
                  const SizedBox(height: 6),
                  Text('Available: ${widget.seats}'),
                  const SizedBox(height: 6),
                  Text('ETA: ${widget.eta}'),
                  const SizedBox(height: 8),
                  const Text('Tap to view more details.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
