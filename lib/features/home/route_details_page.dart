import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';

class RouteDetailsPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const RouteDetailsPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  static const routeName = '/route_details';

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;
    final makerere = const LatLng(0.3392, 32.5736);
    final ntinda = const LatLng(0.3516, 32.6112);
    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [makerere, const LatLng(0.345, 32.587), ntinda],
        color: Theme.of(context).colorScheme.primary,
        width: 5,
      ),
    };
    final busMarkers = {
      Marker(
        markerId: const MarkerId('bus101'),
        position: const LatLng(0.3432, 32.5812),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Bus 101',
          snippet: '18/30 seats available',
        ),
      ),
      Marker(
        markerId: const MarkerId('bus104'),
        position: const LatLng(0.3478, 32.5934),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Bus 104',
          snippet: '6/30 seats available',
        ),
      ),
      Marker(
        markerId: const MarkerId('bus112'),
        position: const LatLng(0.3495, 32.6046),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Bus 112',
          snippet: '2/30 seats available',
        ),
      ),
    };

    final routeMarkers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: makerere,
        infoWindow: const InfoWindow(title: 'Pickup: Makerere'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: ntinda,
        infoWindow: const InfoWindow(title: 'Drop-off: Ntinda'),
      ),
    };

    final markers = {...routeMarkers, ...busMarkers};

    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: makerere,
                      zoom: 12,
                    ),
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Buses',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              children: const [
                                _BusCard(
                                  number: '101',
                                  eta: '4 min',
                                  seats: '18/30',
                                  away: '2.4 km',
                                  status: 'On Route',
                                ),
                                _BusCard(
                                  number: '104',
                                  eta: '7 min',
                                  seats: '6/30',
                                  away: '4.1 km',
                                  status: 'On Route',
                                  color: Colors.orange,
                                ),
                                _BusCard(
                                  number: '112',
                                  eta: '11 min',
                                  seats: '2/30',
                                  away: '6.3 km',
                                  status: 'Almost Full',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: makerere,
                    zoom: 12,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.32,
                  minChildSize: 0.18,
                  maxChildSize: 0.85,
                  builder: (context, controller) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(blurRadius: 8, color: Colors.black26),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$title • $subtitle',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '3 buses found',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              controller: controller,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              children: const [
                                _BusCard(
                                  number: '101',
                                  eta: '4 min',
                                  seats: '18/30',
                                  away: '2.4 km',
                                  status: 'On Route',
                                ),
                                _BusCard(
                                  number: '104',
                                  eta: '7 min',
                                  seats: '6/30',
                                  away: '4.1 km',
                                  status: 'On Route',
                                  color: Colors.orange,
                                ),
                                _BusCard(
                                  number: '112',
                                  eta: '11 min',
                                  seats: '2/30',
                                  away: '6.3 km',
                                  status: 'Almost Full',
                                  color: Colors.red,
                                ),
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _BusCard extends StatefulWidget {
  final String number;
  final String eta;
  final String seats;
  final String away;
  final String status;
  final Color? color;

  const _BusCard({
    required this.number,
    required this.eta,
    required this.seats,
    required this.away,
    required this.status,
    this.color,
  });

  @override
  State<_BusCard> createState() => _BusCardState();
}

class _BusCardState extends State<_BusCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? Colors.green;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BusDetailsPage(number: widget.number, plate: 'UBK 245M'),
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
            subtitle: Text(
              '${widget.eta} • ${widget.seats} seats • ${widget.away}',
            ),
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
                children: const [
                  Text('Driver: John Doe'),
                  SizedBox(height: 6),
                  Text('Plate: UBK 245M'),
                  SizedBox(height: 6),
                  Text('Available seats: 18'),
                  SizedBox(height: 8),
                  Text('Tap to reserve or view more details.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
