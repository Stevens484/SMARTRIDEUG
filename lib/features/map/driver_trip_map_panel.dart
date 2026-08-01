import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

/// Navigation map for the assigned driver. It deliberately receives already
/// scoped booking documents so it never listens to passengers on other buses.
class DriverTripMapPanel extends StatefulWidget {
  const DriverTripMapPanel({
    super.key,
    required this.routeId,
    required this.route,
    required this.bus,
    required this.bookings,
  });

  final String routeId;
  final Map<String, dynamic> route;
  final Map<String, dynamic>? bus;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings;

  @override
  State<DriverTripMapPanel> createState() => _DriverTripMapPanelState();
}

class _DriverTripMapPanelState extends State<DriverTripMapPanel> {
  final _map = MapController();
  final _geometryService = RouteGeometryService();
  late Future<RouteGeometry> _geometry;
  String? _signature;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DriverTripMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = '${widget.routeId}:${widget.route['updatedAt'] ?? ''}';
    if (next != _signature) _load();
  }

  void _load() {
    _signature = '${widget.routeId}:${widget.route['updatedAt'] ?? ''}';
    _geometry = _geometryService.resolve(
      routeId: widget.routeId,
      route: widget.route,
    );
    _fitted = false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RouteGeometry>(
    future: _geometry,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData) {
        return const Center(child: Text('Navigation route is unavailable.'));
      }
      final geometry = snapshot.data!;
      _fit(geometry);
      final busPosition = _position(widget.bus);
      return FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: geometry.origin,
          initialZoom: 13,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.smartrideug.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: geometry.points,
                color: AppTheme.orange,
                strokeWidth: 5,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              _iconMarker(
                geometry.origin,
                Icons.trip_origin_rounded,
                AppTheme.success,
                'Route origin',
              ),
              _iconMarker(
                geometry.destination,
                Icons.flag_rounded,
                AppTheme.orange,
                'Route destination',
              ),
              ...geometry.stops.map(
                (stop) => _iconMarker(
                  stop.position,
                  Icons.location_on_rounded,
                  AppTheme.navy,
                  stop.name,
                ),
              ),
              if (busPosition != null)
                _iconMarker(
                  busPosition,
                  Icons.directions_bus_rounded,
                  AppTheme.orange,
                  'Your bus',
                ),
              ..._passengerMarkers(context, busPosition),
            ],
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      );
    },
  );

  List<Marker> _passengerMarkers(BuildContext context, LatLng? busPosition) {
    const visibleStatuses = {'confirmed', 'active', 'boarding'};
    return widget.bookings
        .where((booking) {
          final status = booking.data()['status']?.toString().toLowerCase();
          return visibleStatuses.contains(status) &&
              _position(booking.data()) != null;
        })
        .map((booking) {
          final data = booking.data();
          final position = _position(data)!;
          final status =
              data['status']?.toString().toLowerCase() ?? 'confirmed';
          final name = data['passengerName']?.toString() ?? 'Passenger';
          final seat = _seat(data);
          final distance = busPosition == null
              ? null
              : const Distance().as(LengthUnit.Meter, busPosition, position);
          return Marker(
            point: position,
            width: 54,
            height: 54,
            child: GestureDetector(
              onTap: () => _showPassengerSheet(
                context,
                data,
                name,
                seat,
                status,
                distance,
              ),
              child: _PassengerPin(
                initials: _initials(name),
                seat: seat,
                color: _markerColor(data, status),
              ),
            ),
          );
        })
        .toList();
  }

  void _showPassengerSheet(
    BuildContext context,
    Map<String, dynamic> booking,
    String name,
    String seat,
    String status,
    double? distance,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _sheetRow('Seat', seat),
              _sheetRow(
                'Pickup stop',
                booking['pickupStopName']?.toString() ??
                    booking['pickupStopId']?.toString() ??
                    'Not selected',
              ),
              _sheetRow(
                'Destination',
                booking['destinationStopName']?.toString() ??
                    booking['destinationStopId']?.toString() ??
                    'Not selected',
              ),
              _sheetRow('Status', status),
              _sheetRow(
                'Estimated pickup',
                booking['estimatedPickupTime']?.toString() ??
                    booking['eta']?.toString() ??
                    'Calculating',
              ),
              _sheetRow(
                'Distance from bus',
                distance == null ? 'Calculating' : '${distance.round()} m',
              ),
              if (booking['passengerPhone'] != null)
                _sheetRow('Phone', booking['passengerPhone'].toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 132,
          child: Text(label, style: const TextStyle(color: AppTheme.grey500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  LatLng? _position(Map<String, dynamic>? data) {
    final latitude =
        data?['liveLatitude'] ?? data?['currentLatitude'] ?? data?['latitude'];
    final longitude =
        data?['liveLongitude'] ??
        data?['currentLongitude'] ??
        data?['longitude'];
    return latitude is num && longitude is num
        ? LatLng(latitude.toDouble(), longitude.toDouble())
        : null;
  }

  String _seat(Map<String, dynamic> data) {
    final value = data['seatNumber'] ?? data['seats'];
    return value is Iterable ? value.join(', ') : value?.toString() ?? '—';
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
      .join();

  Color _markerColor(Map<String, dynamic> booking, String status) {
    if (booking['readyToBoard'] == true) return AppTheme.orange;
    if (booking['boarded'] == true) return AppTheme.success;
    if (status == 'missed') return const Color(0xFFE34A45);
    if (status == 'completed') return AppTheme.grey500;
    return const Color(0xFF2878E8);
  }

  Marker _iconMarker(LatLng point, IconData icon, Color color, String label) =>
      Marker(
        point: point,
        width: 44,
        height: 44,
        child: Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      );

  void _fit(RouteGeometry geometry) {
    if (_fitted || geometry.points.isEmpty) return;
    _fitted = true;
    final lats = geometry.points.map((point) => point.latitude);
    final lngs = geometry.points.map((point) => point.longitude);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final span = (maxLat - minLat).abs() > (maxLng - minLng).abs()
        ? (maxLat - minLat).abs()
        : (maxLng - minLng).abs();
    final zoom = span < .01
        ? 14.5
        : span < .03
        ? 13
        : span < .08
        ? 12
        : span < .2
        ? 10
        : 8;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        _map.move(
          LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          zoom.toDouble(),
        );
    });
  }
}

class _PassengerPin extends StatelessWidget {
  const _PassengerPin({
    required this.initials,
    required this.seat,
    required this.color,
  });
  final String initials;
  final String seat;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        Text(
          seat,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}
