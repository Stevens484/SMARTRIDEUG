import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';

class BookingStatusPage extends StatefulWidget {
  final String bookingId;

  const BookingStatusPage({super.key, required this.bookingId});

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
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
        ),
      ),
    );
  }

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
}
