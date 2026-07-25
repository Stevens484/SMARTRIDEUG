import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});
  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _online = false;
  bool _starting = false;
  DateTime? _lastUpdate;
  StreamSubscription<Position>? _positionSub;
  final _busId = TextEditingController();
  final _busNumber = TextEditingController();
  final _routeId = TextEditingController();

  @override
  void dispose() {
    _positionSub?.cancel();
    _busId.dispose();
    _busNumber.dispose();
    _routeId.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _locationRef => FirebaseFirestore
      .instance
      .collection('busLocations')
      .doc(_busId.text.trim());

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on location services to go online.'),
          ),
        );
      }
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _goOnline() async {
    if (_busId.text.trim().isEmpty ||
        _busNumber.text.trim().isEmpty ||
        _routeId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the bus ID, bus number, and route ID first.'),
        ),
      );
      return;
    }

    setState(() => _starting = true);
    final allowed = await _ensureLocationPermission();
    if (!allowed) {
      setState(() => _starting = false);
      return;
    }

    // Send one update immediately so passengers see the bus right away,
    // rather than waiting for the first movement-triggered update.
    final first = await Geolocator.getCurrentPosition();
    await _sendUpdate(first, status: 'online');

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres — only re-send once the phone has moved
      ),
    ).listen((position) => _sendUpdate(position, status: 'moving'));

    setState(() {
      _online = true;
      _starting = false;
    });
  }

  Future<void> _sendUpdate(Position position, {required String status}) async {
    // Read live seat availability so passengers see an accurate count,
    // not a number that goes stale the moment a seat is booked.
    int? availableSeats;
    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(_busId.text.trim())
          .get();
      final total = (busDoc.data()?['totalSeats'] as num?)?.toInt() ?? 32;
      final reserved = (busDoc.data()?['reservedSeats'] as List?)?.length ?? 0;
      availableSeats = total - reserved;
    } catch (_) {
      // If this read fails, still send the location update below.
    }

    await _locationRef.set({
      'routeId': _routeId.text.trim(),
      'busNumber': _busNumber.text.trim(),
      'status': status,
      'latitude': position.latitude,
      'longitude': position.longitude,
      if (availableSeats != null) 'availableSeats': availableSeats,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) setState(() => _lastUpdate = DateTime.now());
  }

  Future<void> _goOffline() async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (_busId.text.trim().isNotEmpty) {
      await _locationRef.set({
        'status': 'offline',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    setState(() => _online = false);
  }

  Future<void> _logout() async {
    await _goOffline();
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Driver dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: _logout,
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Shift control', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _busId,
          enabled: !_online,
          decoration: const InputDecoration(
            labelText: 'Bus ID (matches Firestore document, e.g. bus001)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _busNumber,
          enabled: !_online,
          decoration: const InputDecoration(
            labelText: 'Bus number shown to passengers (e.g. 14)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _routeId,
          enabled: !_online,
          decoration: const InputDecoration(labelText: 'Current route ID'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _online,
          onChanged: _starting
              ? null
              : (value) => value ? _goOnline() : _goOffline(),
          title: Text(
            _starting
                ? 'Starting...'
                : _online
                ? 'Online — sharing real live location'
                : 'Offline',
          ),
          subtitle: Text(
            _online && _lastUpdate != null
                ? 'Last update: ${_lastUpdate!.hour.toString().padLeft(2, '0')}:'
                      '${_lastUpdate!.minute.toString().padLeft(2, '0')}:'
                      '${_lastUpdate!.second.toString().padLeft(2, '0')}'
                : 'Your phone\'s real GPS position is sent automatically '
                      'while online.',
          ),
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
            if (!s.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              );
            }
            if (s.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No passengers waiting.'),
              );
            }
            return Column(
              children: s.data!.docs
                  .map(
                    (d) => Card(
                      child: ListTile(
                        title: Text('Booking ${d.id.substring(0, 6)}'),
                        subtitle: Text(
                          'Seats: ${(d.data()['seats'] ?? []).join(', ')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (d.data()['pickupLatitude'] != null &&
                                d.data()['pickupLongitude'] != null)
                              IconButton(
                                icon: const Icon(Icons.location_pin),
                                tooltip: 'View pickup location',
                                onPressed: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => _PickupLocationSheet(
                                    latitude:
                                        (d.data()['pickupLatitude'] as num)
                                            .toDouble(),
                                    longitude:
                                        (d.data()['pickupLongitude'] as num)
                                            .toDouble(),
                                  ),
                                ),
                              ),
                            FilledButton(
                              onPressed: () => d.reference.update({
                                'status': 'boarded',
                                'boardedAt': FieldValue.serverTimestamp(),
                              }),
                              child: const Text('Boarded'),
                            ),
                          ],
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

/// Shown when a driver taps the pin next to a waiting passenger — the
/// passenger's real, one-time-captured pickup location.
class _PickupLocationSheet extends StatelessWidget {
  const _PickupLocationSheet({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Passenger pickup location',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.mhl.smart_ride_ug',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
