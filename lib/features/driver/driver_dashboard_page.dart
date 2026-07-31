import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  StreamSubscription<Position>? _positionSubscription;
  String? _activeBusId;
  bool _isOnline = false;
  bool _isChangingStatus = false;
  String? _locationMessage;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking(
    QueryDocumentSnapshot<Map<String, dynamic>> bus,
  ) async {
    if (_isChangingStatus) return;
    setState(() => _isChangingStatus = true);
    try {
      if (_isOnline) {
        await _positionSubscription?.cancel();
        _positionSubscription = null;
        await bus.reference.update({
          'status': 'offline',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            _isOnline = false;
            _activeBusId = null;
            _locationMessage = null;
          });
        }
        return;
      }

      final locationReady = await _requestLocationPermission();
      if (!locationReady) return;

      await bus.reference.update({
        'status': 'online',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _publishPosition(bus.reference, initialPosition);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (position) => _publishPosition(bus.reference, position),
            onError: (_) {
              if (mounted) {
                setState(
                  () => _locationMessage =
                      'Location updates paused. Check GPS, then try again.',
                );
              }
            },
          );
      if (mounted) {
        setState(() {
          _isOnline = true;
          _activeBusId = bus.id;
          _locationMessage = null;
        });
      }
    } on TimeoutException {
      await _markOffline(bus.reference);
      if (mounted) {
        setState(
          () => _locationMessage =
              'Could not get your location. Try going online again.',
        );
      }
    } catch (error) {
      await _markOffline(bus.reference);
      if (mounted) {
        setState(() => _locationMessage = 'Unable to go online: $error');
      }
    } finally {
      if (mounted) setState(() => _isChangingStatus = false);
    }
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: _DriverMessage(
          icon: Icons.lock_person_outlined,
          message: 'Sign in as a driver to access your assigned trip.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver dashboard')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .where('driverId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _DriverMessage(
              icon: Icons.error_outline,
              message: 'Your assigned trip could not be loaded.',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _DriverMessage(
              icon: Icons.directions_bus_outlined,
              message:
                  'You do not have a bus assigned yet. Ask an administrator to assign one.',
            );
          }
          final bus = snapshot.data!.docs.first;
          return _AssignedTrip(
            bus: bus,
            online: _isOnline && _activeBusId == bus.id,
            busy: _isChangingStatus,
            locationMessage: _locationMessage,
            onToggle: () => _toggleTracking(bus),
          );
        },
      ),
    );
  }
}

class _AssignedTrip extends StatelessWidget {
  const _AssignedTrip({
    required this.bus,
    required this.online,
    required this.busy,
    required this.locationMessage,
    required this.onToggle,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> bus;
  final bool online;
  final bool busy;
  final String? locationMessage;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = bus.data();
    final busName = (data['busNumber'] ?? data['registrationNumber'] ?? bus.id)
        .toString();
    final route = (data['routeName'] ?? data['routeId'] ?? 'Route pending')
        .toString();
    final departure = data['departureTime']?.toString();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your assigned trip',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: colors.onPrimary,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus $busName',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                    if (departure != null && departure.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Scheduled departure: $departure',
                        style: TextStyle(
                          color: colors.onPrimaryContainer.withValues(
                            alpha: .75,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Live location', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          online
              ? 'Your GPS position is being shared with passengers on the live map.'
              : 'Go online when you are ready to share this bus on the passenger map.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: online
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: online ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                online ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                color: online ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  online ? 'Online and tracking' : 'Offline',
                  style: TextStyle(
                    color: online
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(value: online, onChanged: busy ? null : (_) => onToggle()),
            ],
          ),
        ),
        if (locationMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              locationMessage!,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy ? null : onToggle,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  online ? Icons.pause_circle_outline : Icons.play_circle_fill,
                ),
          label: Text(online ? 'Go offline' : 'Go online and share GPS'),
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
