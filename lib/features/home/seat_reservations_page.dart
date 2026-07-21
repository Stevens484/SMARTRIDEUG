import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

class SeatReservationsPage extends StatelessWidget {
  const SeatReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seat Reservations')),
        body: const Center(child: Text('Sign in to view your reservations.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seat Reservations')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservations = snapshot.data!.docs;
          if (reservations.isEmpty) {
            return const Center(child: Text('No seat reservations found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reservation = reservations[index].data();
              final route =
                  reservation['routeId']?.toString() ?? 'Unknown route';
              final bus = reservation['busId']?.toString() ?? 'Unknown bus';
              final seats =
                  (reservation['seats'] as List<dynamic>?)
                      ?.map((s) => s.toString())
                      .join(', ') ??
                  'Unknown seats';
              final status = reservation['status']?.toString() ?? 'Unknown';

              return Card(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingStatusPage(
                        bookingId: reservations[index].id,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Bus $bus â€¢ Seat(s) $seats'),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(status),
                          backgroundColor: status == 'confirmed'
                              ? Colors.green
                              : status == 'pending'
                              ? Colors.orange
                              : status == 'cancelled'
                              ? Colors.red
                              : Colors.grey,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
