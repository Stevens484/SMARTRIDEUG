import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

class SeatReservationsPage extends StatelessWidget {
  const SeatReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seat reservations')),
        body: const Center(child: Text('Sign in to view your reservations.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Seat reservations')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load your reservations.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reservations = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aCreatedAt = a.data()['createdAt'];
              final bCreatedAt = b.data()['createdAt'];
              final aDate = aCreatedAt is Timestamp
                  ? aCreatedAt.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = bCreatedAt is Timestamp
                  ? bCreatedAt.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
          if (reservations.isEmpty) {
            return const Center(child: Text('No seat reservations found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reservation = reservations[index].data();
              final routeName = reservation['routeName']?.toString();
              final route = routeName?.isNotEmpty == true
                  ? routeName!
                  : '${reservation['origin'] ?? ''} → ${reservation['destination'] ?? ''}';
              final plate = reservation['plateNumber']?.toString();
              final bus = plate?.isNotEmpty == true
                  ? plate!
                  : reservation['busNumber']?.toString() ?? 'Bus unavailable';
              final seats =
                  (reservation['seats'] as Iterable?)?.join(', ') ??
                  'Seats unavailable';
              final status =
                  reservation['status']?.toString().toLowerCase() ?? 'unknown';
              final color = switch (status) {
                'confirmed' => Colors.green,
                'held' => Colors.orange,
                'cancelled' => Colors.red,
                _ => Theme.of(context).colorScheme.onSurfaceVariant,
              };
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingStatusPage(bookingId: reservations[index].id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.trim().isEmpty ? 'Route unavailable' : route,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Bus $bus • Held seat(s): $seats'),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: Icon(
                            status == 'held'
                                ? Icons.lock_clock_outlined
                                : status == 'confirmed'
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text('Seat status: ${status.toUpperCase()}'),
                          backgroundColor: color,
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
