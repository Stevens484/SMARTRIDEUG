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
    // Prevent double-tap
    if (_isReserving) return;

    setState(() => _isReserving = true);

    try {
      final bookingId = await TransitRepository().reserveSeats(
        busId: widget.busId,
        routeId: widget.routeId,
        seats: widget.seats,
        farePerSeat: widget.farePerSeat,
      );

      if (!mounted) return;

      // Navigate to booking status page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingStatusPage(bookingId: bookingId),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Confirm Seat'), elevation: 0),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load route details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final routeData = snapshot.data?.data();
          final origin = routeData?['origin']?.toString() ?? 'Not specified';
          final destination =
              routeData?['destination']?.toString() ?? 'Not specified';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 Booking Summary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
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
                                    Text(
                                      'Bus ID: ${widget.busId}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _infoRow('Selected Seats', widget.seats.join(', ')),
                          _infoRow('Seats Count', '${widget.seats.length}'),
                          _infoRow('Pickup', origin),
                          _infoRow('Drop-off', destination),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔥 Fare Section
                  const Text(
                    'Fare Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.seats.length} seat${widget.seats.length > 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'UGX ${widget.farePerSeat} per seat',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'UGX ${widget.farePerSeat * widget.seats.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 🔥 Reserve Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isReserving ? null : _reserveSeats,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isReserving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.seats.length == 1
                                  ? 'Reserve Seat'
                                  : 'Reserve ${widget.seats.length} Seats',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔥 Note
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You have 2 minutes to confirm your booking',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
