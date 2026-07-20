import 'package:flutter/material.dart';

class SeatReservationsPage extends StatelessWidget {
  const SeatReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservations = const [
      {
        'route': 'Makerere → Ntinda',
        'bus': '101',
        'seat': '08',
        'status': 'Confirmed',
      },
      {
        'route': 'Kampala City Centre → Entebbe',
        'bus': '215',
        'seat': '16',
        'status': 'Pending',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Seat Reservations')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: reservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation['route']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bus ${reservation['bus']} • Seat ${reservation['seat']}',
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(reservation['status']!),
                    backgroundColor: reservation['status'] == 'Confirmed'
                        ? Colors.green
                        : reservation['status'] == 'Pending'
                        ? Colors.orange
                        : Colors.grey,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
