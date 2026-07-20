import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking Confirmed')),
    body: SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final booking = snapshot.data!.data();
          if (booking == null) return const Center(child: Text('This booking is no longer available.'));
          final seats = (booking['seats'] as List<dynamic>? ?? const []).join(', ');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.check_circle, size: 96, color: Colors.green),
                const SizedBox(height: 16),
                const Text('Ride Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your booking is confirmed.'),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bus: ${booking['busId'] ?? 'Unavailable'}'),
                      const SizedBox(height: 8),
                      Text('Seat(s): $seats'),
                      const SizedBox(height: 8),
                      Text('Route: ${booking['routeId'] ?? 'Unavailable'}'),
                      const SizedBox(height: 8),
                      Text('Fare: UGX ${booking['fare'] ?? 0}'),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('View Ticket'),
                )),
              ],
            ),
          );
        },
      ),
    ),
  );
}
