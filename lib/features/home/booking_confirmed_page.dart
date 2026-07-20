import 'package:flutter/material.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.check_circle, size: 96, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Ride Confirmed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Your booking is confirmed.'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Bus: BUS 101 (UBK 245M)'),
                      SizedBox(height: 8),
                      Text('Seat: 09 • Window - Front Left'),
                      SizedBox(height: 8),
                      Text('Pickup: Makerere Main Gate'),
                      SizedBox(height: 8),
                      Text('Drop-off: Ntinda'),
                      SizedBox(height: 8),
                      Text('Fare: UGX 3,000'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('View Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
