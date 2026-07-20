import 'package:flutter/material.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';

class BookingStatusPage extends StatefulWidget {
  const BookingStatusPage({super.key});

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
  bool cancelled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Status')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      ListTile(
                        leading: Icon(
                          Icons.hourglass_top,
                          color: Colors.orange,
                        ),
                        title: Text('Pending'),
                        subtitle: Text('Waiting for arrival...'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: cancelled
                    ? null
                    : () {
                        // simulate confirmation for demo
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const BookingConfirmedPage(),
                          ),
                        );
                      },
                child: const Text("Simulate Confirm"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: cancelled
                    ? null
                    : () {
                        setState(() => cancelled = true);
                      },
                child: const Text('Cancel Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
