import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:geolocator/geolocator.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

class ConfirmSeatPage extends StatefulWidget {
  final String busId;
  final String routeId;
  final String busNumber;
  final int farePerSeat;
  final List<String> seats;
=======
import 'package:smartrideug/features/home/momo_payment_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

/// Reviews the exact bus and route selected on the seat layout before a hold
/// is created. The booking fields are supplied by the server, never by labels
/// on this page.
class ConfirmSeatPage extends StatefulWidget {
  const ConfirmSeatPage({
    super.key,
    required this.busId,
    required this.routeId,
<<<<<<< HEAD
    required this.busNumber,
    required this.farePerSeat,
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
    required this.seats,
  });

  final String busId;
  final String routeId;
  final List<String> seats;

  @override
  State<ConfirmSeatPage> createState() => _ConfirmSeatPageState();
}

class _ConfirmSeatPageState extends State<ConfirmSeatPage> {
<<<<<<< HEAD
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _routeFuture;
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    _routeFuture = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeId)
        .get();
  }

  Future<void> _reserveSeats() async {
    // Prevent double-tap
    if (_isReserving) return;

    setState(() => _isReserving = true);

    // Capture the passenger's real location once, as their pickup point —
    // this is best-effort: if permission is denied or location is off, the
    // booking still goes through, just without a pickup point attached.
    double? pickupLat;
    double? pickupLng;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition();
          pickupLat = position.latitude;
          pickupLng = position.longitude;
        }
      }
    } catch (_) {
      // Location capture is best-effort — proceed without it.
    }

    try {
      final bookingId = await TransitRepository().reserveSeats(
        busId: widget.busId,
        routeId: widget.routeId,
        seats: widget.seats,
        farePerSeat: widget.farePerSeat,
        pickupLatitude: pickupLat,
        pickupLongitude: pickupLng,
      );

      if (!mounted) return;

      // Navigate to booking status page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingStatusPage(bookingId: bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Seat'), elevation: 0),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load route details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final routeData = snapshot.data?.data();
          final origin = routeData?['origin']?.toString() ?? 'Not specified';
          final destination =
              routeData?['destination']?.toString() ?? 'Not specified';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 Booking Summary Card
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
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BUS ${widget.busNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'Bus ID: ${widget.busId}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _infoRow('Selected Seats', widget.seats.join(', ')),
                          _infoRow('Seats Count', '${widget.seats.length}'),
                          _infoRow('Pickup', origin),
                          _infoRow('Drop-off', destination),
                        ],
=======
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(widget.routeId)
            .snapshots(),
        builder: (context, routeSnapshot) {
          final route = routeSnapshot.data?.data();
          if (route == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Review your trip')),
              body: const Center(
                child: Text('The selected route is no longer available.'),
              ),
            );
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('buses')
                .doc(widget.busId)
                .snapshots(),
            builder: (context, busSnapshot) =>
                _page(context, route, busSnapshot.data?.data()),
          );
        },
      );

  Widget _page(
    BuildContext context,
    Map<String, dynamic> route,
    Map<String, dynamic>? bus,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final origin = route['origin']?.toString() ?? 'Origin unavailable';
    final destination =
        route['destination']?.toString() ?? 'Destination unavailable';
    final busLabel = bus?['plateNumber']?.toString().trim().isNotEmpty == true
        ? bus!['plateNumber'].toString()
        : bus?['plate']?.toString().trim().isNotEmpty == true
        ? bus!['plate'].toString()
        : bus?['busNumber']?.toString() ?? widget.busId;
    final pickup = route['origin']?.toString() ?? 'Pickup point unavailable';
    return Scaffold(
      appBar: AppBar(title: const Text('Review your trip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your journey',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: .78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          origin,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: scheme.secondary,
                      ),
                      Expanded(
                        child: Text(
                          destination,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Board at $pickup',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: .78),
                      fontSize: 13,
                    ),
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 24),

                  // 🔥 Fare Section
                  const Text(
                    'Fare Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.seats.length} seat${widget.seats.length > 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'UGX ${widget.farePerSeat} per seat',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'UGX ${widget.farePerSeat * widget.seats.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 🔥 Reserve Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isReserving ? null : _reserveSeats,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isReserving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.seats.length == 1
                                  ? 'Reserve Seat'
                                  : 'Reserve ${widget.seats.length} Seats',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔥 Note
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You have 2 minutes to confirm your booking',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
=======
                ],
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 210,
                child: RouteMapPanel(routeId: widget.routeId, route: route),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _detail(
                      context,
                      Icons.directions_bus_outlined,
                      'Bus',
                      busLabel,
                    ),
                    _detail(
                      context,
                      Icons.event_seat_outlined,
                      'Selected seat${widget.seats.length == 1 ? '' : 's'}',
                      widget.seats.join(', '),
                    ),
                    _detail(
                      context,
                      Icons.person_outline,
                      'Passenger${widget.seats.length == 1 ? '' : 's'}',
                      '${widget.seats.length}',
                    ),
                    _detail(
                      context,
                      Icons.location_on_outlined,
                      'Pickup',
                      pickup,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MomoPaymentPage(
                      busId: widget.busId,
                      routeId: widget.routeId,
                      seats: widget.seats,
                    ),
                  ),
                ),
                child: const Text('Continue to MoMo pay'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is a temporary seat hold. When your bus is within 100 m of the pickup point, you will be asked to confirm that you are ready.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 19,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
}
