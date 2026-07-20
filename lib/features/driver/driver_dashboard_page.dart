import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/transit_repository.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});
  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _online = false;
  final _bus = TextEditingController();
  final _route = TextEditingController();
  @override
  void dispose() {
    _bus.dispose();
    _route.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_bus.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the assigned bus ID first.')),
      );
      return;
    }
    setState(() => _online = !_online);
    await FirebaseFirestore.instance
        .collection('busStatus')
        .doc(_bus.text.trim())
        .set({
          'status': _online ? 'online' : 'offline',
          'routeId': _route.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Driver dashboard')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Shift control', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _bus,
          decoration: const InputDecoration(labelText: 'Assigned bus ID'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _route,
          decoration: const InputDecoration(labelText: 'Current route ID'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _online,
          onChanged: (_) => _toggle(),
          title: Text(_online ? 'Online — sharing live status' : 'Offline'),
          subtitle: const Text(
            'GPS updates should be sent by your location service while online.',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _online
              ? () => TransitRepository().updateBusLocation(
                  busId: _bus.text.trim(),
                  latitude: 0.3476,
                  longitude: 32.5825,
                  status: 'moving',
                )
              : null,
          icon: const Icon(Icons.my_location),
          label: const Text('Send current location update'),
        ),
        const SizedBox(height: 24),
        Text(
          'Passengers waiting',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('status', whereIn: ['pending', 'confirmed'])
              .snapshots(),
          builder: (_, s) {
            if (!s.hasData)
              return const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              );
            if (s.data!.docs.isEmpty)
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No passengers waiting.'),
              );
            return Column(
              children: s.data!.docs
                  .map(
                    (d) => Card(
                      child: ListTile(
                        title: Text('Booking ${d.id.substring(0, 6)}'),
                        subtitle: Text(
                          'Seats: ${(d.data()['seats'] ?? []).join(', ')}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => d.reference.update({
                            'status': 'boarded',
                            'boardedAt': FieldValue.serverTimestamp(),
                          }),
                          child: const Text('Boarded'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
