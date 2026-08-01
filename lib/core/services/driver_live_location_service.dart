import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Publishes a driver's assigned bus only while its trip is active.
class DriverLiveLocationService {
  DriverLiveLocationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  StreamSubscription<Position>? _subscription;

  Future<void> start({
    required String busId,
    required String routeId,
    required String driverId,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on location services to begin the trip.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError(
        'Location permission is required to share the bus position.',
      );
    }

    final records = await Future.wait([
      _db.collection('buses').doc(busId).get(),
      _db.collection('routes').doc(routeId).get(),
    ]);
    final bus = records[0].data();
    final route = records[1].data();
    if (bus == null || route == null) {
      throw StateError('Your assigned bus or route is no longer available.');
    }

    // A compact assignment snapshot lets passenger maps render a live bus
    // without allowing drivers to modify the admin-owned buses collection.
    final assignment = <String, dynamic>{
      'busId': busId,
      'busNumber': bus['busNumber']?.toString() ?? busId,
      'availableSeats': bus['availableSeats'],
      'totalSeats': bus['totalSeats'],
      'driverId': driverId,
      'routeId': routeId,
      'routeName': route['name']?.toString() ?? routeId,
      'origin': route['origin']?.toString(),
      'destination': route['destination']?.toString(),
    };

    await _subscription?.cancel();
    await _db.collection('busLocations').doc(busId).set({
      ...assignment,
      'status': 'moving',
      'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _db.collection('busStatus').doc(busId).set({
      ...assignment,
      'status': 'online',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((position) {
      _db.collection('busLocations').doc(busId).set({
        ...assignment,
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        // Existing map views read these fields as well.
        'latitude': position.latitude,
        'longitude': position.longitude,
        'status': 'moving',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> stop(String busId) async {
    await _subscription?.cancel();
    _subscription = null;
    final update = <String, dynamic>{
      'status': 'offline',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db
        .collection('busLocations')
        .doc(busId)
        .set(update, SetOptions(merge: true));
    await _db.collection('busStatus').doc(busId).set(
      update,
      SetOptions(merge: true),
    );
  }

  Future<void> dispose() => _subscription?.cancel() ?? Future.value();
}
