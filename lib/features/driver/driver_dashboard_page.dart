import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
=======
import 'package:smartrideug/core/services/driver_live_location_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/theme/theme_notifier.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/map/driver_trip_map_panel.dart';
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final _location = DriverLiveLocationService();
  bool _online = false;
<<<<<<< HEAD
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
=======
  bool _saving = false;

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _toggle(String busId, String routeId, String driverId) async {
    setState(() => _saving = true);
    try {
      if (_online) {
        await _location.stop(busId);
      } else {
        await _location.start(
          busId: busId,
          routeId: routeId,
          driverId: driverId,
        );
      }
      await FirebaseFirestore.instance.collection('busStatus').doc(busId).set({
        'status': _online ? 'offline' : 'online',
        'routeId': routeId,
        'driverId': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() => _online = !_online);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout([String? assignedBusId]) async {
    final busId = assignedBusId?.trim() ?? '';
    if (_online && busId.isNotEmpty) {
      try {
        await _location.stop(busId);
      } catch (_) {
        // Logging out should remain possible if location shutdown is unavailable.
      }
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthenticationPage.routeName, (_) => false);
    }
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  }

  Future<bool> _requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(
          () => _locationMessage =
              'Turn on location services before starting your trip.',
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
        setState(
          () => _locationMessage =
              'Location permission is required to share the bus position.',
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _markOffline(DocumentReference<Map<String, dynamic>> bus) async {
    try {
      await bus.update({
        'status': 'offline',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Preserve the original location error for the driver.
    }
  }

  Future<void> _publishPosition(
    DocumentReference<Map<String, dynamic>> bus,
    Position position,
  ) => bus.update({
    'latitude': position.latitude,
    'longitude': position.longitude,
    'speed': position.speed.isFinite ? position.speed : 0,
    'heading': position.heading.isFinite ? position.heading : 0,
    'status': 'moving',
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Driver dashboard'),
      actions: [
        IconButton(
<<<<<<< HEAD
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
          'Your assigned trip',
          style: Theme.of(context).textTheme.headlineSmall,
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
=======
          tooltip: Theme.of(context).brightness == Brightness.dark
              ? 'Use light mode'
              : 'Use dark mode',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => themeNotifier.toggleTheme(
            Theme.of(context).brightness != Brightness.dark,
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: _logout,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
      ],
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final assignment = snapshot.data?.data();
        final busId = (assignment?['assignedBusId'] ?? assignment?['busId'])
            ?.toString()
            .trim();
        final routeId =
            (assignment?['assignedRouteId'] ?? assignment?['routeId'])
                ?.toString()
                .trim();
        if (busId == null ||
            busId.isEmpty ||
            routeId == null ||
            routeId.isEmpty) {
          return const _AssignmentPendingCard();
        }
        final driverId = FirebaseAuth.instance.currentUser?.uid;
        if (driverId == null) return const _AssignmentPendingCard();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text('Active trip', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('buses')
                      .doc(busId)
                      .snapshots(),
                  builder: (context, busSnapshot) =>
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('routes')
                            .doc(routeId)
                            .snapshots(),
                        builder: (context, routeSnapshot) {
                          final bus = busSnapshot.data?.data();
                          final route = routeSnapshot.data?.data();
                          final plate =
                              bus?['plateNumber']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? bus!['plateNumber'].toString()
                              : bus?['plate']?.toString().trim().isNotEmpty ==
                                    true
                              ? bus!['plate'].toString()
                              : bus?['busNumber']?.toString() ??
                                    'Bus unavailable';
                          final routeName =
                              route?['name']?.toString() ?? 'Route unavailable';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assigned bus: $plate'),
                              const SizedBox(height: 4),
                              Text('Assigned route: $routeName'),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _toggle(busId, routeId, driverId),
                                  icon: Icon(
                                    _online
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline,
                                  ),
                                  label: Text(
                                    _online
                                        ? 'End active trip'
                                        : 'Start active trip',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_online)
              _activeTrip(busId, routeId)
            else
              const _InactiveTripCard(),
          ],
        );
      },
    ),
  );

  Widget _activeTrip(String busId, String routeId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .snapshots(),
      builder: (context, routeSnapshot) {
        final route = routeSnapshot.data?.data();
        if (route == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Waiting for the assigned route to become available.',
              ),
            ),
          );
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('busLocations')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnapshot) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('busId', isEqualTo: busId)
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  final bookings = bookingSnapshot.data?.docs ?? const [];
                  final activeCount = bookings.where((booking) {
                    const statuses = {'confirmed', 'active', 'boarding'};
                    return statuses.contains(
                      booking.data()['status']?.toString().toLowerCase(),
                    );
                  }).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            color: AppTheme.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$activeCount passengers awaiting pickup',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 410,
                          child: DriverTripMapPanel(
                            routeId: routeId,
                            route: route,
                            bus: busSnapshot.data?.data(),
                            bookings: bookings,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Passenger pins show confirmed, active, and boarding requests only. Tap one for pickup details.',
                        style: TextStyle(color: AppTheme.grey500),
                      ),
                    ],
                  );
                },
              ),
        );
      },
    );
  }
}

class _InactiveTripCard extends StatelessWidget {
  const _InactiveTripCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.gps_off_rounded, color: AppTheme.grey500),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Start your trip to share bus location and view active passenger pickups.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _AssignmentPendingCard extends StatelessWidget {
  const _AssignmentPendingCard();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late_outlined, size: 42),
              SizedBox(height: 12),
              Text(
                'You have not been assigned a bus and route yet.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'Please contact an administrator.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
    );
  }
}

class _DriverMessage extends StatelessWidget {
  const _DriverMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
