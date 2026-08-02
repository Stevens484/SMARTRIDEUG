import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _actionSubscription = LocalNotificationService.instance.actions.listen((
      action,
    ) {
      if (action.bookingId != widget.bookingId) return;
      if (action.actionId == 'confirm') {
        _confirmBooking();
      } else if (action.actionId == 'cancel') {
        _cancelBooking();
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _actionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final snapshot = await _bookingRef.get();
      final booking = snapshot.data();
      final expiresAt = booking?['expiresAt'];
      if (booking == null || expiresAt is! Timestamp) {
        throw StateError('Your payment window is not available.');
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MomoPaymentPage(
            bookingId: widget.bookingId,
            fare: (booking['fare'] as num?)?.toInt() ?? 0,
            expiresAt: expiresAt.toDate(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
=======
  final _location = PassengerLiveLocationService();
  final _repository = TransitRepository();
  bool _locationStarted = false;
  bool _processing = false;
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

  Future<void> _cancelBooking() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await TransitRepository().cancelBooking(widget.bookingId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _expireBooking() async {
    try {
      await TransitRepository().expireBooking(widget.bookingId);
    } catch (_) {
      // The stream will continue to show the pending state if a network error
      // occurs, allowing the next foreground update to try again safely.
    }
  }

  void _scheduleExpiry(Map<String, dynamic> booking) {
    final expiresAt = booking['expiresAt'];
    if (expiresAt is! Timestamp) return;
    final milliseconds = expiresAt.millisecondsSinceEpoch;
    if (_scheduledExpiryMilliseconds == milliseconds) return;
    _scheduledExpiryMilliseconds = milliseconds;
    _expiryTimer?.cancel();
    final delay = expiresAt.toDate().difference(DateTime.now());
    _expiryTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      _expireBooking,
    );
  }

  void _watchArrival({
    required Map<String, dynamic> booking,
    required Map<String, dynamic> bus,
    required Map<String, dynamic> stop,
  }) {
    if (_checkingArrival || booking['arrivalNotifiedAt'] != null) return;
    final latitude = bus['latitude'];
    final longitude = bus['longitude'];
    final stopLatitude = stop['latitude'];
    final stopLongitude = stop['longitude'];
    if (latitude is! num ||
        longitude is! num ||
        stopLatitude is! num ||
        stopLongitude is! num) {
      return;
    }
    final metres = Geolocator.distanceBetween(
      latitude.toDouble(),
      longitude.toDouble(),
      stopLatitude.toDouble(),
      stopLongitude.toDouble(),
    );
    if (metres > 100) return;

    _checkingArrival = true;
    unawaited(() async {
      try {
        final opened = await TransitRepository().markBusArrived(
          widget.bookingId,
        );
        if (opened) {
          await LocalNotificationService.instance.showBusArrival(
            widget.bookingId,
          );
        }
      } finally {
        _checkingArrival = false;
      }
    }());
  }

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
            if (status != 'pending_confirmation') {
              return _content(
                booking: booking,
                status: status,
                readyToConfirm: false,
              );
            }

            _scheduleExpiry(booking);
            final busId = booking['busId']?.toString() ?? '';
            final stopId = booking['pickupStopId']?.toString() ?? '';
            final routeId = booking['routeId']?.toString() ?? '';
            if (busId.isEmpty || stopId.isEmpty || routeId.isEmpty) {
              return _content(
                booking: booking,
                status: status,
                readyToConfirm: false,
              );
            }
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('buses')
                  .doc(busId)
                  .snapshots(),
              builder: (context, busSnapshot) {
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('routes')
                      .doc(routeId)
                      .collection('stops')
                      .doc(stopId)
                      .snapshots(),
                  builder: (context, stopSnapshot) {
                    final bus = busSnapshot.data?.data();
                    final stop = stopSnapshot.data?.data();
                    if (bus != null && stop != null) {
                      _watchArrival(booking: booking, bus: bus, stop: stop);
                    }
                    final expiresAt = booking['expiresAt'];
                    final readyToConfirm =
                        booking['arrivalNotifiedAt'] != null &&
                        expiresAt is Timestamp &&
                        expiresAt.toDate().isAfter(DateTime.now());
                    return _content(
                      booking: booking,
                      status: status,
                      readyToConfirm: readyToConfirm,
                    );
                  },
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
            height: 54,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "I'm Ready — Confirm Trip",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (status == 'pending_confirmation')
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isUpdating ? null : _cancelBooking,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Cancel Booking',
                      style: TextStyle(color: Colors.red),
                    ),
            ),
          ),
        if (status == 'confirmed') ...[
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BookingConfirmedPage(bookingId: widget.bookingId),
                ),
              ),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('View QR Ticket'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if ({'confirmed', 'cancelled', 'expired'}.contains(status))
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Go Home'),
            ),
          ),
      ],
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
