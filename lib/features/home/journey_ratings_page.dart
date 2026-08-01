import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/transit_repository.dart';

/// Lets passengers leave feedback against a real booking.
class JourneyRatingsPage extends StatelessWidget {
  const JourneyRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate a journey')),
        body: const Center(child: Text('Sign in to rate a journey.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Rate a journey')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your journeys.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings =
              snapshot.data!.docs.where((booking) {
                const eligible = {'confirmed', 'boarded', 'completed'};
                return eligible.contains(
                  booking.data()['status']?.toString().toLowerCase(),
                );
              }).toList()..sort((a, b) {
                final aTime = a.data()['createdAt'] as Timestamp?;
                final bTime = b.data()['createdAt'] as Timestamp?;
                return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                  aTime?.millisecondsSinceEpoch ?? 0,
                );
              });
          if (bookings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your confirmed journeys will appear here for rating.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _JourneyRatingCard(booking: bookings[index]),
          );
        },
      ),
    );
  }
}

class _JourneyRatingCard extends StatefulWidget {
  const _JourneyRatingCard({required this.booking});

  final QueryDocumentSnapshot<Map<String, dynamic>> booking;

  @override
  State<_JourneyRatingCard> createState() => _JourneyRatingCardState();
}

class _JourneyRatingCardState extends State<_JourneyRatingCard> {
  final _repository = TransitRepository();
  bool _saving = false;
  late int _journey;
  late int _driver;
  late int _bus;

  @override
  void initState() {
    super.initState();
    final data = widget.booking.data();
    _journey = (data['journeyRating'] as num?)?.toInt() ?? 0;
    _driver = (data['driverRating'] as num?)?.toInt() ?? 0;
    _bus = (data['busRating'] as num?)?.toInt() ?? 0;
  }

  Future<void> _save() async {
    if (_journey == 0 || _driver == 0 || _bus == 0) {
      _show('Select a star rating for the journey, driver, and bus.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.submitJourneyRatings(
        bookingId: widget.booking.id,
        journeyRating: _journey,
        driverRating: _driver,
        busRating: _bus,
      );
      _show('Thank you for your feedback.');
    } catch (error) {
      _show(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.booking.data();
    final route = data['routeName']?.toString().trim().isNotEmpty == true
        ? data['routeName'].toString()
        : '${data['origin'] ?? ''} to ${data['destination'] ?? ''}';
    final plate = data['plateNumber']?.toString().trim().isNotEmpty == true
        ? data['plateNumber'].toString()
        : data['busNumber']?.toString() ?? 'Assigned bus';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(route, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Bus: $plate'),
            const SizedBox(height: 14),
            _RatingRow(
              label: 'Journey',
              value: _journey,
              onChanged: (value) => setState(() => _journey = value),
            ),
            _RatingRow(
              label: 'Driver',
              value: _driver,
              onChanged: (value) => setState(() => _driver = value),
            ),
            _RatingRow(
              label: 'Bus',
              value: _bus,
              onChanged: (value) => setState(() => _bus = value),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save ratings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 72, child: Text(label)),
      for (var star = 1; star <= 5; star += 1)
        IconButton(
          tooltip: '$star stars',
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            color: star <= value ? Colors.amber.shade700 : null,
          ),
        ),
    ],
  );
}
