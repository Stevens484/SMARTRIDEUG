import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/passenger_live_location_service.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class BookingStatusPage extends StatefulWidget {
  const BookingStatusPage({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
  final _location = PassengerLiveLocationService();
  final _repository = TransitRepository();
  bool _locationStarted = false;
  bool _processing = false;
  Future<BookingTripEta>? _etaFuture;
  String? _etaSignature;

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  void _syncLiveLocation(Map<String, dynamic>? booking) {
    if (booking == null) return;
    const waiting = {'held', 'confirmed', 'active', 'boarding'};
    final status = booking['status']?.toString().toLowerCase();
    if (waiting.contains(status) && !_locationStarted) {
      _locationStarted = true;
      _location.start(widget.bookingId).catchError((_) {
        if (mounted) setState(() => _locationStarted = false);
      });
    } else if (!waiting.contains(status) && _locationStarted) {
      _locationStarted = false;
      _location.stop(widget.bookingId, boarded: status == 'boarded');
    }
  }

  Future<BookingTripEta>? _etaFor(
    Map<String, dynamic> booking,
    Map<String, dynamic>? location,
  ) {
    final latitude = location?['currentLatitude'] ?? location?['latitude'];
    final longitude = location?['currentLongitude'] ?? location?['longitude'];
    if (latitude is! num || longitude is! num) return null;
    // GPS updates can be very frequent. Rounding to ~11 m preserves a useful
    // live ETA while preventing a duplicate road-route request for tiny moves.
    final signature = [
      booking['busId'],
      booking['pickupStopId'],
      booking['destinationStopId'],
      latitude.toDouble().toStringAsFixed(4),
      longitude.toDouble().toStringAsFixed(4),
    ].join(':');
    if (signature != _etaSignature) {
      _etaSignature = signature;
      _etaFuture = _repository.estimateBookingEta(
        booking: booking,
        location: location,
      );
    }
    return _etaFuture;
  }

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      await _repository.confirmSeatHold(widget.bookingId);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(bookingId: widget.bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _processing = true);
    try {
      await _repository.cancelSeatHold(widget.bookingId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, bookingSnapshot) {
          final booking = bookingSnapshot.data?.data();
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (booking == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Booking status')),
              body: const Center(child: Text('This booking is unavailable.')),
            );
          }
          _syncLiveLocation(booking);
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('busLocations')
                .doc(booking['busId'])
                .snapshots(),
            builder: (context, locationSnapshot) =>
                _page(context, booking, locationSnapshot.data?.data()),
          );
        },
      );

  Widget _page(
    BuildContext context,
    Map<String, dynamic> booking,
    Map<String, dynamic>? location,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final status = booking['status']?.toString().toLowerCase() ?? 'held';
    final distance = _distanceToPickup(booking, location);
    final eta = _etaFor(booking, location);
    final canConfirm = status == 'held' && distance != null && distance <= 100;
    final title = status == 'confirmed'
        ? 'Seat confirmed'
        : status == 'cancelled'
        ? 'Booking cancelled'
        : canConfirm
        ? 'Your bus has arrived'
        : 'Seat held';
    final message = status == 'confirmed'
        ? 'Your seat is now permanently reserved. Show your ticket when you board.'
        : status == 'cancelled'
        ? 'This seat hold has been released.'
        : canConfirm
        ? 'Your bus is at the pickup point. Confirm that you are ready to board.'
        : distance == null
        ? 'We are waiting for the bus to share its live location.'
        : 'We will prompt you when the bus is within 100 m of your pickup point.';
    return Scaffold(
      appBar: AppBar(title: const Text('Booking status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(
                        status == 'confirmed'
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        color: scheme.secondary,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _routeMap(booking),
            const SizedBox(height: 18),
            _LiveTripEta(
              eta: eta,
              pickupName:
                  booking['pickupStopName']?.toString() ?? 'Pickup point',
              destinationName:
                  booking['destinationStopName']?.toString() ?? 'Stop',
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 22),
                    _detail(context, 'Booking ID', widget.bookingId),
                    _detail(
                      context,
                      'Bus',
                      booking['plateNumber']?.toString().isNotEmpty == true
                          ? booking['plateNumber'].toString()
                          : booking['busNumber']?.toString() ?? 'Unavailable',
                    ),
                    _detail(
                      context,
                      'Route',
                      '${booking['origin'] ?? ''} → ${booking['destination'] ?? ''}',
                    ),
                    _detail(
                      context,
                      'Pickup',
                      booking['pickupStopName']?.toString() ?? 'Unavailable',
                    ),
                    _detail(
                      context,
                      'Seats',
                      (booking['seats'] as Iterable?)?.join(', ') ??
                          'Unavailable',
                    ),
                    if (distance != null)
                      _detail(
                        context,
                        'Bus distance',
                        '${distance.round()} m from pickup',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (status == 'held' && canConfirm) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _confirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _processing ? 'Confirming...' : 'I am ready to board',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (status == 'held')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _processing ? null : _cancel,
                  child: const Text('Cancel seat hold'),
                ),
              ),
            if (status == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingConfirmedPage(bookingId: widget.bookingId),
                    ),
                  ),
                  child: const Text('View digital ticket'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _routeMap(Map<String, dynamic> booking) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(booking['routeId'])
            .snapshots(),
        builder: (context, routeSnapshot) {
          final route = routeSnapshot.data?.data();
          if (route == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: RouteMapPanel(
                routeId: booking['routeId'].toString(),
                route: route,
              ),
            ),
          );
        },
      );

  double? _distanceToPickup(
    Map<String, dynamic> booking,
    Map<String, dynamic>? location,
  ) {
    final pickupLat = booking['pickupLatitude'];
    final pickupLng = booking['pickupLongitude'];
    final busLat = location?['currentLatitude'] ?? location?['latitude'];
    final busLng = location?['currentLongitude'] ?? location?['longitude'];
    if (pickupLat is! num ||
        pickupLng is! num ||
        busLat is! num ||
        busLng is! num) {
      return null;
    }
    return const Distance().as(
      LengthUnit.Meter,
      LatLng(pickupLat.toDouble(), pickupLng.toDouble()),
      LatLng(busLat.toDouble(), busLng.toDouble()),
    );
  }

  Widget _detail(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
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

class _LiveTripEta extends StatelessWidget {
  const _LiveTripEta({
    required this.eta,
    required this.pickupName,
    required this.destinationName,
  });

  final Future<BookingTripEta>? eta;
  final String pickupName;
  final String destinationName;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: FutureBuilder<BookingTripEta>(
        future: eta,
        builder: (context, snapshot) {
          if (eta == null) {
            return const _EtaMessage(
              icon: Icons.location_searching_outlined,
              text: 'Waiting for the bus to share its live location.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _EtaMessage(
              icon: Icons.schedule_outlined,
              text: 'Calculating your live road-route ETA…',
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const _EtaMessage(
              icon: Icons.schedule_outlined,
              text: 'Live ETA is temporarily unavailable.',
            );
          }
          final value = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live trip ETA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text('Calculated from the bus’s current GPS location.'),
              const SizedBox(height: 14),
              _EtaRow(
                icon: Icons.my_location_outlined,
                label: 'Pickup · $pickupName',
                minutes: value.pickupMinutes,
              ),
              const SizedBox(height: 10),
              _EtaRow(
                icon: Icons.location_on_outlined,
                label: 'Stop · $destinationName',
                minutes: value.destinationMinutes,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _EtaMessage extends StatelessWidget {
  const _EtaMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(child: Text(text)),
    ],
  );
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({
    required this.icon,
    required this.label,
    required this.minutes,
  });
  final IconData icon;
  final String label;
  final int minutes;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(label)),
      Text(
        minutes <= 1 ? 'Arriving now' : '~$minutes min',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );
}
