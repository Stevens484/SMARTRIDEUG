import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// Publishes a waiting passenger's position only while their booking is active.
class PassengerLiveLocationService {
  PassengerLiveLocationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  StreamSubscription<Position>? _positionSubscription;

  Future<void> start(String bookingId) async {
    final permission = await _permission();
    if (!permission)
      throw StateError(
        'Location permission is required while waiting for the bus.',
      );
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) => _publish(bookingId, position));
  }

  Future<void> stop(String bookingId, {bool boarded = false}) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _db.collection('bookings').doc(bookingId).set({
      'liveLocationActive': false,
      'liveLocationStoppedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> dispose() => _positionSubscription?.cancel() ?? Future.value();

  Future<bool> _permission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _publish(String bookingId, Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('bookings').doc(bookingId).set({
      'passengerId': user.uid,
      'liveLatitude': position.latitude,
      'liveLongitude': position.longitude,
      'liveLocationActive': true,
      'liveLocationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
