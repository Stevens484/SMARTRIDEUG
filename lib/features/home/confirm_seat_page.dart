import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

class ConfirmSeatPage extends StatefulWidget {
  final String busId;
  final String routeId;
  final String busNumber;
  final int farePerSeat;
  final List<String> seats;

  const ConfirmSeatPage({
    super.key,
    required this.busId,
    required this.routeId,
    required this.busNumber,
    required this.farePerSeat,
    required this.seats,
  });

  @override
  State<ConfirmSeatPage> createState() => _ConfirmSeatPageState();
}

class _ConfirmSeatPageState extends State<ConfirmSeatPage> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _routeFuture;
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    _routeFuture = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeId)
        .get();
  }

  Future<void> _reserveSeats() async {
    setState(() => _isReserving = true);

    try {
      final bookingId = await TransitRepository().reserveSeats(
        busId: widget.busId,
        routeId: widget.routeId,
        seats: widget.seats,
        farePerSeat: widget.farePerSeat,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingStatusPage(bookingId: bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Seat')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final routeData = snapshot.data?.data();
          final origin = routeData?['origin']?.toString() ?? 'Not specified';
          final destination =
              routeData?['destination']?.toString() ?? 'Not specified';

          return SafeArea(
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
                              'BUS ${widget.busNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Selected Seats: ${widget.seats.join(', ')}'),
                            const SizedBox(height: 8),
                            Text('Seats selected: ${widget.seats.length}'),
                            const SizedBox(height: 8),
                            Text('Pickup: $origin'),
                            const SizedBox(height: 8),
                            Text('Drop-off: $destination'),
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
                      'UGX ${widget.farePerSeat * widget.seats.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isReserving ? null : _reserveSeats,
                        child: _isReserving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.seats.length == 1
                                    ? 'Reserve Seat'
                                    : 'Reserve ${widget.seats.length} Seats',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
