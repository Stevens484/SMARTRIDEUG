import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

class ConfirmSeatPage extends StatelessWidget {
  final String busNumber;
  final List<String> seats;

  const ConfirmSeatPage({
    super.key,
    required this.busNumber,
    required this.seats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Seat')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUS $busNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Selected Seats: ${seats.join(', ')}'),
                        const SizedBox(height: 8),
                        Text('Seats selected: ${seats.length}'),
                        const SizedBox(height: 8),
                        const Text('Pickup: Makerere Main Gate'),
                        const SizedBox(height: 8),
                        const Text('Drop-off: Ntinda'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fare',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'UGX ${3000 * seats.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BookingStatusPage(),
                      ),
                    ),
                    child: Text(
                      seats.length == 1
                          ? 'Reserve Seat'
                          : 'Reserve ${seats.length} Seats',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
