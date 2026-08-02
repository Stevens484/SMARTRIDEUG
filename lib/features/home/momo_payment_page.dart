import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

/// MoMo checkout uses separately managed pickup points and stops. The quoted
/// distance is the road path through the configured route, never a direct-line
/// distance between the two selected places.
class MomoPaymentPage extends StatefulWidget {
  const MomoPaymentPage({
    super.key,
    required this.busId,
    required this.routeId,
    required this.seats,
  });

  final String busId;
  final String routeId;
  final List<String> seats;

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage> {
  final _phone = TextEditingController();
  final _repository = TransitRepository();
  String? _pickupStopId;
  String? _destinationStopId;
  Future<TripFareQuote>? _fareQuote;
  bool _paying = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _choosePickup(String? value) {
    setState(() {
      _pickupStopId = value;
      _destinationStopId = null;
      _fareQuote = null;
    });
  }

  void _chooseDestination(String? value) {
    setState(() {
      _destinationStopId = value;
      _fareQuote = value == null || _pickupStopId == null
          ? null
          : _repository.quoteFare(
              routeId: widget.routeId,
              pickupStopId: _pickupStopId!,
              destinationStopId: value,
            );
    });
  }

  Future<void> _payAndHold() async {
    if (_pickupStopId == null) {
      _message('Choose your pickup point.');
      return;
    }
    if (_destinationStopId == null) {
      _message('Choose your destination stop.');
      return;
    }
    if (_phone.text.trim().length < 9) {
      _message('Enter the Mobile Money number to use.');
      return;
    }
    setState(() => _paying = true);
    try {
      // Quote again while creating the hold so the saved fare always reflects
      // the current admin-managed route and its road path.
      final bookingId = await _repository.createSeatHold(
        busId: widget.busId,
        routeId: widget.routeId,
        seats: widget.seats,
        pickupStopId: _pickupStopId!,
        destinationStopId: _destinationStopId!,
        momoPhone: _phone.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BookingStatusPage(bookingId: bookingId),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MoMo pay')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.routeId)
          .collection('stops')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final points = snapshot.data!.docs.toList()
          ..sort(
            (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
              (b.data()['order'] as num?)?.toInt() ?? 99999,
            ),
          );
        final pickups = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (var index = 0; index < points.length - 1; index += 1) {
          final type = points[index].data()['type']?.toString();
          if (_isRoutePoint(type)) {
            pickups.add(points[index]);
          }
        }
        final pickupIndex = points.indexWhere(
          (point) => point.id == _pickupStopId,
        );
        final stops = <QueryDocumentSnapshot<Map<String, dynamic>>>[
          if (pickupIndex >= 0)
            for (var index = pickupIndex + 1; index < points.length; index += 1)
              if (_isRoutePoint(points[index].data()['type']?.toString()))
                points[index],
        ];
        final validPickup = pickups.any((point) => point.id == _pickupStopId);
        final validDestination = stops.any(
          (point) => point.id == _destinationStopId,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay with MTN MoMo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose where you will board and where you will get off.',
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('pickup-${widget.routeId}'),
                      initialValue: validPickup ? _pickupStopId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Your boarding point',
                        prefixIcon: Icon(Icons.my_location_outlined),
                      ),
                      items: pickups
                          .map(
                            (point) => DropdownMenuItem(
                              value: point.id,
                              child: Text(
                                point.data()['name']?.toString() ??
                                    'Pickup point',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _choosePickup,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // Rebuild the field when pickup changes. This clears an
                      // invalid previous stop and immediately requests a new
                      // road-route fare for the next selected pair.
                      key: ValueKey(
                        'stop-${widget.routeId}-${_pickupStopId ?? ''}',
                      ),
                      initialValue: validDestination
                          ? _destinationStopId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Your destination stop',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: stops
                          .map(
                            (point) => DropdownMenuItem(
                              value: point.id,
                              child: Text(
                                point.data()['name']?.toString() ?? 'Stop',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _pickupStopId == null
                          ? null
                          : _chooseDestination,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'MTN MoMo number',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FareAndPayment(
              quote: _fareQuote,
              seatCount: widget.seats.length,
              paying: _paying,
              onPay: _payAndHold,
            ),
          ],
        );
      },
    ),
  );
}

bool _isRoutePoint(String? type) {
  final normalized = type?.trim().toLowerCase();
  return normalized == 'pickup' ||
      normalized == 'pickup_point' ||
      normalized == 'pickup point' ||
      normalized == 'stop' ||
      normalized == 'destination' ||
      normalized == 'both';
}

class _FareAndPayment extends StatelessWidget {
  const _FareAndPayment({
    required this.quote,
    required this.seatCount,
    required this.paying,
    required this.onPay,
  });

  final Future<TripFareQuote>? quote;
  final int seatCount;
  final bool paying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) => FutureBuilder<TripFareQuote>(
    future: quote,
    builder: (context, snapshot) {
      final quoteValue = snapshot.data;
      final error = snapshot.hasError
          ? snapshot.error.toString().replaceFirst('Bad state: ', '')
          : null;
      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin-set route fare',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Calculating the road distance…'
                              : error ??
                                    (quoteValue == null
                                        ? 'Select a pickup and stop to see the fare.'
                                        : '${quoteValue.distanceKm.toStringAsFixed(1)} km on route · fixed for this pickup and stop'),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    quoteValue == null
                        ? '—'
                        : 'UGX ${quoteValue.farePerSeat * seatCount}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: paying || quoteValue == null ? null : onPay,
            icon: const Icon(Icons.lock_outline),
            label: Text(
              paying
                  ? 'Creating seat hold...'
                  : 'Pay and hold ${seatCount == 1 ? 'seat' : 'seats'}',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The administrator sets this fare for your selected pickup and stop. Road distance is used for the route and arrival estimate.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );
}
