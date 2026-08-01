import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';

/// MoMo checkout for a selected bus. The fare rate is read from the
/// administrator-managed origin pickup and is never editable by a passenger.
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
  String? _destinationStopId;
  bool _paying = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _payAndHold(_Fare fare) async {
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
      final bookingId = await _repository.createSeatHold(
        busId: widget.busId,
        routeId: widget.routeId,
        seats: widget.seats,
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
        final stops = snapshot.data!.docs.toList()
          ..sort(
            (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
              (b.data()['order'] as num?)?.toInt() ?? 99999,
            ),
          );
        if (stops.length < 2) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This route needs an origin and destination stop before payment is available.',
              ),
            ),
          );
        }
        final fare = _Fare.fromStops(stops, _destinationStopId);
        final destinations = stops.skip(1).toList();
        final validDestination = destinations.any(
          (stop) => stop.id == _destinationStopId,
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
                    Text(
                      'Origin: ${stops.first.data()['name'] ?? 'Route origin'}',
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: validDestination
                          ? _destinationStopId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Your destination stop',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: destinations
                          .map(
                            (stop) => DropdownMenuItem(
                              value: stop.id,
                              child: Text(
                                stop.data()['name']?.toString() ?? 'Stop',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _destinationStopId = value),
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
                            'Admin-set fare',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            fare == null
                                ? 'Select a destination to see the fare.'
                                : '${fare.distanceKm.toStringAsFixed(1)} km × UGX ${fare.ratePerKm.toInt()} per km',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fare == null
                          ? '—'
                          : 'UGX ${fare.total * widget.seats.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _paying || fare == null
                  ? null
                  : () => _payAndHold(fare),
              icon: const Icon(Icons.lock_outline),
              label: Text(
                _paying
                    ? 'Creating seat hold...'
                    : 'Pay and hold ${widget.seats.length == 1 ? 'seat' : 'seats'}',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The fare is set by the administrator for this route. A MoMo payment record is saved with your seat hold.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    ),
  );
}

class _Fare {
  const _Fare({
    required this.ratePerKm,
    required this.distanceKm,
    required this.total,
  });
  final num ratePerKm;
  final double distanceKm;
  final int total;

  static _Fare? fromStops(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stops,
    String? destinationId,
  ) {
    final destinationIndex = stops.indexWhere(
      (stop) => stop.id == destinationId,
    );
    if (destinationIndex <= 0) {
      return null;
    }
    final rate = stops.first.data()['farePerKilometre'] as num?;
    final points = stops.take(destinationIndex + 1).map((stop) {
      final data = stop.data();
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      return latitude is num && longitude is num
          ? LatLng(latitude.toDouble(), longitude.toDouble())
          : null;
    }).toList();
    if (rate == null || rate <= 0 || points.any((point) => point == null)) {
      return null;
    }
    var metres = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      metres += const Distance().as(
        LengthUnit.Meter,
        points[index - 1]!,
        points[index]!,
      );
    }
    final km = metres / 1000;
    return _Fare(ratePerKm: rate, distanceKm: km, total: (km * rate).round());
  }
}
