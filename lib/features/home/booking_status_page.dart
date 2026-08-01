import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/passenger_live_location_service.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class BookingStatusPage extends StatefulWidget {
<<<<<<< HEAD
  final String bookingId;

  const BookingStatusPage({super.key, required this.bookingId});
=======
  const BookingStatusPage({super.key, required this.bookingId});
  final String bookingId;
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
<<<<<<< HEAD
  bool _isCancelling = false;
  bool _autoCancellationScheduled = false;
  bool _expired = false;

  DocumentReference<Map<String, dynamic>> get _bookingRef =>
      FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

  Future<void> _writeNotification(String title, String body) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // A missing notification shouldn't break the booking flow itself.
      debugPrint('Could not write notification: $error');
    }
  }

  Future<void> _confirmBooking() async {
    try {
      await _bookingRef.update({'status': 'confirmed'});
      await _writeNotification(
        'Booking confirmed',
        'Your seat booking is confirmed. Have a safe trip!',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(bookingId: widget.bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _cancelAndRelease(
    Map<String, dynamic> booking, {
    bool expired = false,
  }) async {
    setState(() => _isCancelling = true);

    try {
      final busId = booking['busId']?.toString();
      if (busId == null || busId.isEmpty) {
        throw StateError('The booking does not have a bus assigned.');
      }
      final seats = List<String>.from(booking['seats'] as List? ?? const []);
      final reservationSnapshot = await FirebaseFirestore.instance
          .collection('seatReservations')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();
      final reservationRef = reservationSnapshot.docs.isEmpty
          ? null
          : reservationSnapshot.docs.first.reference;
      final busRef = FirebaseFirestore.instance.collection('buses').doc(busId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentBooking = await transaction.get(_bookingRef);
        if (!currentBooking.exists) {
          throw StateError('This booking is no longer available.');
        }
        if (currentBooking.data()?['status'] != 'pending') {
          throw StateError('This booking can no longer be cancelled.');
        }

        final bus = await transaction.get(busRef);
        final reservedSeats = List<String>.from(
          bus.data()?['reservedSeats'] as List? ?? const [],
        );
        transaction.update(_bookingRef, {'status': 'cancelled'});
        transaction.update(busRef, {
          'reservedSeats': reservedSeats
              .where((seat) => !seats.contains(seat))
              .toList(),
        });
        if (reservationRef != null) {
          transaction.update(reservationRef, {'status': 'cancelled'});
        }
      });

      await _writeNotification(
        expired ? 'Reservation expired' : 'Booking cancelled',
        expired
            ? 'Your seat reservation expired before you confirmed, so it '
                  'was released.'
            : 'You cancelled your seat booking.',
      );

      if (expired && mounted) {
        setState(() => _expired = true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
=======
  final _location = PassengerLiveLocationService();
  final _repository = TransitRepository();
  bool _locationStarted = false;
  bool _processing = false;
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

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
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Booking Status'), elevation: 0),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _bookingRef.snapshots(),
          builder: (context, bookingSnapshot) {
            if (!bookingSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final booking = bookingSnapshot.data!.data();
            if (booking == null) {
              return const Center(
                child: Text('This booking is no longer available.'),
              );
            }
            final status = booking['status']?.toString() ?? 'unknown';

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('seatReservations')
                  .where('bookingId', isEqualTo: widget.bookingId)
                  .limit(1)
                  .snapshots(),
              builder: (context, reservationSnapshot) {
                if (!reservationSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reservation = reservationSnapshot.data!.docs.isEmpty
                    ? null
                    : reservationSnapshot.data!.docs.first.data();
                final expiresAt = reservation?['expiresAt'] as Timestamp?;
                final hasExpired =
                    status == 'pending' &&
                    expiresAt != null &&
                    DateTime.now().isAfter(expiresAt.toDate());
                if (hasExpired && !_autoCancellationScheduled) {
                  _autoCancellationScheduled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _cancelAndRelease(booking, expired: true);
                  });
                }

                var icon = Icons.help_outline;
                var color = Colors.grey;
                var title = status;
                var subtitle = 'Unknown booking status';
                switch (status) {
                  case 'pending':
                    icon = Icons.hourglass_top;
                    color = Colors.orange;
                    title = 'Pending';
                    subtitle = 'Waiting for you to confirm';
                    break;
                  case 'confirmed':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    title = 'Confirmed';
                    subtitle = "You're all set";
                    break;
                  case 'cancelled':
                    icon = Icons.cancel;
                    color = Colors.red;
                    title = 'Cancelled';
                    subtitle = _expired
                        ? 'This reservation expired before you confirmed.'
                        : 'This booking was cancelled';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 🔥 Status Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 🔥 Booking Details
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Booking Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _detailRow('Booking ID', widget.bookingId),
                              _detailRow(
                                'Bus',
                                booking['busNumber']?.toString() ?? 'N/A',
                              ),
                              _detailRow(
                                'Route',
                                booking['routeName']?.toString() ?? 'N/A',
                              ),
                              _detailRow(
                                'Seats',
                                (booking['seats'] as List?)?.join(', ') ??
                                    'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // 🔥 Action Buttons (only show if pending)
                      if (status == 'pending') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isCancelling ? null : _confirmBooking,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "I'm Ready — Confirm Trip",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isCancelling
                                ? null
                                : () => _cancelAndRelease(booking),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isCancelling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Cancel Booking',
                                    style: TextStyle(color: Colors.red),
                                  ),
                          ),
                        ),
                      ],

                      // 🔥 Back to Home button (when booking is done)
                      if (status == 'confirmed' || status == 'cancelled') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            child: const Text('Go Home'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
=======
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
}
