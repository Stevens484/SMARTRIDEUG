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
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Seat Reservations'), elevation: 0),
=======
      appBar: AppBar(title: const Text('Seat reservations')),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            // 🔥 FIX: Changed 'passengerId' to 'userId'
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
<<<<<<< HEAD

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reservations: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No seat reservations found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book a seat from the live map to get started!',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final reservations = snapshot.data!.docs;
=======
          final reservations = snapshot.data!.docs;
          if (reservations.isEmpty) {
            return const Center(child: Text('No seat reservations found.'));
          }
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
<<<<<<< HEAD
              final data = reservations[index].data();
              final docId = reservations[index].id;
              final route = data['routeName']?.toString() ?? 'Unknown route';
              final bus = data['busId']?.toString() ?? 'Unknown bus';
              final seats = data['seat']?.toString() ?? 'Unknown';
              final status = data['status']?.toString() ?? 'Unknown';

              Color statusColor;
              switch (status) {
                case 'confirmed':
                  statusColor = Colors.green;
                  break;
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingStatusPage(bookingId: docId),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                route,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Bus: $bus'),
                        const SizedBox(height: 4),
                        Text('Seat: $seats'),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
=======
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
                        Text('Bus $bus • Seat(s) $seats'),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(status.toUpperCase()),
                          backgroundColor: color,
                          labelStyle: const TextStyle(color: Colors.white),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
