import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/local_notification_service.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';
import 'package:smartrideug/features/home/payment_method_page.dart';

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
  String? _pickupStopId;
  String? _pickupName;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _routeFuture = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeId)
        .get();
  }

  Future<void> _createBooking({required String routeName}) async {
    if (_isCreating) return;
    if (_pickupStopId == null || _pickupName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose your pickup stop first.')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await LocalNotificationService.instance.requestPermission();
      final bookingId = await TransitRepository().createPendingBooking(
        busId: widget.busId,
        routeId: widget.routeId,
        busNumber: widget.busNumber,
        routeName: routeName,
        pickupStopId: _pickupStopId!,
        pickupStopName: _pickupName!,
        seats: widget.seats,
        farePerSeat: widget.farePerSeat,
      );
      if (!mounted) return;
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Seat'), elevation: 0),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _routeFuture,
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (routeSnapshot.hasError) {
              return const Center(child: Text('Failed to load route details.'));
            }

            final route = routeSnapshot.data?.data();
            final origin = route?['origin']?.toString() ?? 'Not specified';
            final destination =
                route?['destination']?.toString() ?? 'Not specified';
            final routeName = '$origin to $destination';
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .doc(widget.routeId)
                  .collection('stops')
                  .snapshots(),
              builder: (context, stopsSnapshot) {
                if (!stopsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (stopsSnapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load the pickup stops for this route.',
                    ),
                  );
                }
                final stops = stopsSnapshot.data!.docs.toList()
                  ..sort(
                    (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 999999)
                        .compareTo(
                          (b.data()['order'] as num?)?.toInt() ?? 999999,
                        ),
                  );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                    color: AppTheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                            _infoRow('Route', routeName),
                            StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: FirebaseFirestore.instance
                                  .collection('buses')
                                  .doc(widget.busId)
                                  .snapshots(),
                              builder: (context, busSnapshot) {
                                final bus = busSnapshot.data?.data();
                                final driverName = bus?['driverName']
                                    ?.toString()
                                    .trim();
                                return _infoRow(
                                  'Driver',
                                  driverName?.isNotEmpty == true
                                      ? driverName!
                                      : 'Driver details will be available when assigned.',
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Pickup stops on this route',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  stops.any((stop) => stop.id == _pickupStopId)
                                  ? _pickupStopId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Pickup stop',
                                border: OutlineInputBorder(),
                              ),
                              hint: Text(
                                stops.isEmpty
                                    ? 'No stops added by the admin yet'
                                    : 'Choose pickup stop',
                              ),
                              items: stops
                                  .map(
                                    (stop) => DropdownMenuItem(
                                      value: stop.id,
                                      child: Text(
                                        '${(stop.data()['name'] ?? stop.id).toString()}${stop.data()['latitude'] is num && stop.data()['longitude'] is num ? '' : ' (location needed)'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: stops.isEmpty
                                  ? null
                                  : (value) {
                                      final selected = stops.firstWhere(
                                        (stop) => stop.id == value,
                                      );
                                      setState(() {
                                        _pickupStopId = value;
                                        _pickupName =
                                            (selected.data()['name'] ??
                                                    selected.id)
                                                .toString();
                                      });
                                    },
                            ),
                            if (_pickupName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Arrival alert: $_pickupName',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Fare Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
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
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'UGX ${widget.farePerSeat * widget.seats.length}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (FirebaseAuth.instance.currentUser != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('paymentMethods')
                            .where('isDefault', isEqualTo: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, paymentSnapshot) {
                          final methods =
                              paymentSnapshot.data?.docs ?? const [];
                          final method = methods.isEmpty
                              ? null
                              : methods.first.data();
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet,
                                  color: AppTheme.primary,
                              ),
                              title: const Text('Payment method'),
                              subtitle: Text(
                                method == null
                                    ? 'No MTN MoMo number saved — you can enter one at checkout.'
                                    : '${method['title'] ?? 'MTN MoMo'} • ${method['subtitle'] ?? ''}',
                              ),
                              trailing: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PaymentMethodPage(),
                                  ),
                                ),
                                child: Text(method == null ? 'Add' : 'Change'),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isCreating || stops.isEmpty
                            ? null
                            : () => _createBooking(routeName: routeName),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCreating
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
                                    ? 'Hold Seat'
                                    : 'Hold ${widget.seats.length} Seats',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seats are held until your bus arrives. You then have 2 minutes to confirm.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
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
