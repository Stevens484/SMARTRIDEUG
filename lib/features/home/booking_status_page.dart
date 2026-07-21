import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _confirmBooking() async {
    try {
      await _bookingRef.update({'status': 'confirmed'});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(bookingId: widget.bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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

      if (expired && mounted) {
        setState(() => _expired = true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
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
      appBar: AppBar(title: const Text('Booking Status')),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _bookingRef.snapshots(),
          builder: (context, bookingSnapshot) {
            if (!bookingSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final booking = bookingSnapshot.data!.data();
            if (booking == null) {
              return const Center(child: Text('This booking is no longer available.'));
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(title),
                            subtitle: Text(subtitle),
                          ),
                        ),
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isCancelling ? null : _confirmBooking,
                          child: const Text("I'm Ready"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isCancelling
                              ? null
                              : () => _cancelAndRelease(booking),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Cancel Booking'),
                        ),
                      ],
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
}
