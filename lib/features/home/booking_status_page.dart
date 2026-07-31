import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartrideug/core/services/local_notification_service.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';
import 'package:smartrideug/features/home/momo_payment_page.dart';

class BookingStatusPage extends StatefulWidget {
  final String bookingId;

  const BookingStatusPage({super.key, required this.bookingId});

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
  bool _isUpdating = false;
  bool _checkingArrival = false;
  Timer? _expiryTimer;
  int? _scheduledExpiryMilliseconds;
  StreamSubscription<ArrivalNotificationAction>? _actionSubscription;

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
  Widget build(BuildContext context) {
    return Scaffold(
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
        ),
      ),
    );
  }

  Widget _content({
    required Map<String, dynamic> booking,
    required String status,
    required bool readyToConfirm,
  }) {
    var icon = Icons.help_outline;
    var color = AppTheme.grey500;
    var title = status;
    var subtitle = 'Unknown booking status';
    switch (status) {
      case 'pending_confirmation':
        icon = readyToConfirm ? Icons.directions_bus : Icons.hourglass_top;
        color = readyToConfirm ? AppTheme.primary : AppTheme.navy;
        title = readyToConfirm ? 'Your bus has arrived' : 'Seat held';
        subtitle = readyToConfirm
            ? 'Are you ready to board? Confirm within 2 minutes.'
            : 'We will alert you when your bus reaches the pickup stop.';
        break;
      case 'confirmed':
        icon = Icons.check_circle;
        color = AppTheme.success;
        title = 'Confirmed';
        subtitle = "You're all set";
        break;
      case 'cancelled':
      case 'expired':
        icon = Icons.cancel;
        color = Colors.red;
        title = status == 'expired' ? 'Expired' : 'Cancelled';
        subtitle = status == 'expired'
            ? 'Your temporary seat hold has been released.'
            : 'Your temporary seat hold has been released.';
        break;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _detailRow('Booking ID', widget.bookingId),
                _detailRow('Bus', booking['busNumber']?.toString() ?? 'N/A'),
                _detailRow('Route', booking['routeName']?.toString() ?? 'N/A'),
                _detailRow(
                  'Pickup',
                  booking['pickupStopName']?.toString() ?? 'N/A',
                ),
                _detailRow(
                  'Seats',
                  (booking['seats'] as List?)?.join(', ') ?? 'N/A',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (status == 'pending_confirmation' && readyToConfirm) ...[
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

  Widget _detailRow(String label, String value) => Padding(
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
