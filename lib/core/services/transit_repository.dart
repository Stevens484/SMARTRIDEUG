import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class TransitRepository {
  TransitRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> liveBuses() => _db
      .collection('busLocations')
      .where(
        'status',
        whereIn: ['online', 'moving', 'approaching_stop', 'stopped'],
      )
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> routes() =>
      _db.collection('routes').where('active', isEqualTo: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> myBookings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('bookings')
        .where('passengerId', isEqualTo: uid)
        .snapshots();
  }

<<<<<<< HEAD
  Future<String> reserveSeats({
=======
  Future<String> createSeatHold({
    required String busId,
    required String routeId,
    required List<String> seats,
    required String destinationStopId,
    required String momoPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to hold a seat.');
    if (seats.isEmpty || seats.length > 8) {
      throw StateError('Choose between one and eight seats.');
    }
    final routeSnapshot = await _db.collection('routes').doc(routeId).get();
    final stopsSnapshot = await routeSnapshot.reference
        .collection('stops')
        .get();
    final stops = stopsSnapshot.docs.toList()
      ..sort(
        (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
          (b.data()['order'] as num?)?.toInt() ?? 99999,
        ),
      );
    if (!routeSnapshot.exists || stops.length < 2) {
      throw StateError('This route needs at least two mapped stops.');
    }
    final destinationIndex = stops.indexWhere(
      (stop) => stop.id == destinationStopId,
    );
    if (destinationIndex <= 0) {
      throw StateError('Choose a destination stop after the route origin.');
    }
    final tripStops = stops.take(destinationIndex + 1).toList();
    final pickup = tripStops.first.data();
    final destination = tripStops.last.data();
    final farePerKilometre = pickup['farePerKilometre'] as num?;
    final distanceKm = _distanceKilometres(
      tripStops.map((stop) => stop.data()),
    );
    if (farePerKilometre == null ||
        farePerKilometre <= 0 ||
        distanceKm == null) {
      throw StateError(
        'The pickup needs a fare per kilometre and mapped coordinates.',
      );
    }
    final bookingRef = _db.collection('bookings').doc();
    await _db.runTransaction((transaction) async {
      final busRef = _db.collection('buses').doc(busId);
      final busSnapshot = await transaction.get(busRef);
      if (!busSnapshot.exists) {
        throw StateError('The selected bus is unavailable.');
      }
      final bus = busSnapshot.data()!;
      if (bus['routeId'] != null && bus['routeId'].toString() != routeId) {
        throw StateError('This bus is no longer assigned to that route.');
      }
      final totalSeats = (bus['totalSeats'] as num?)?.toInt() ?? 0;
      if (seats.any(
        (seat) =>
            int.tryParse(seat) == null ||
            int.parse(seat) <= 1 ||
            int.parse(seat) > totalSeats,
      )) {
        throw StateError('One of the selected seats is unavailable.');
      }
      final taken = (bus['reservedSeats'] as List<dynamic>? ?? const [])
          .map((seat) => seat.toString())
          .toSet();
      final holdRefs = seats
          .map((seat) => _db.collection('seatHolds').doc('${busId}_$seat'))
          .toList();
      final holds = await Future.wait(holdRefs.map(transaction.get));
      if (seats.any(taken.contains) || holds.any((hold) => hold.exists)) {
        throw StateError('One or more selected seats have just been taken.');
      }
      final farePerSeat = (distanceKm * farePerKilometre).round();
      transaction.set(bookingRef, {
        'passengerId': user.uid,
        'busId': busId,
        'busNumber': bus['busNumber']?.toString() ?? busId,
        'plateNumber':
            bus['plateNumber']?.toString() ?? bus['plate']?.toString() ?? '',
        'routeId': routeId,
        'routeName': routeSnapshot.data()?['name']?.toString() ?? routeId,
        'origin': routeSnapshot.data()?['origin']?.toString() ?? '',
        'destination': routeSnapshot.data()?['destination']?.toString() ?? '',
        'pickupStopId': tripStops.first.id,
        'pickupStopName': pickup['name']?.toString() ?? '',
        'pickupLatitude': pickup['latitude'],
        'pickupLongitude': pickup['longitude'],
        'destinationStopId': tripStops.last.id,
        'destinationStopName': destination['name']?.toString() ?? '',
        'seats': seats,
        'farePerKilometre': farePerKilometre,
        'distanceKm': distanceKm,
        'farePerSeat': farePerSeat,
        'fare': farePerSeat * seats.length,
        'paymentMethod': 'momo',
        'momoPhone': momoPhone,
        'paymentStatus': 'pending',
        'status': 'held',
        'readyToBoard': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (var index = 0; index < seats.length; index += 1) {
        transaction.set(holdRefs[index], {
          'bookingId': bookingRef.id,
          'passengerId': user.uid,
          'busId': busId,
          'routeId': routeId,
          'seat': seats[index],
          'status': 'held',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
    return bookingRef.id;
  }

  Future<void> confirmSeatHold(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to confirm your seat.');
    await _db.runTransaction((transaction) async {
      final bookingRef = _db.collection('bookings').doc(bookingId);
      final bookingSnapshot = await transaction.get(bookingRef);
      final booking = bookingSnapshot.data();
      if (booking == null ||
          booking['passengerId'] != user.uid ||
          booking['status'] != 'held') {
        throw StateError('This seat hold is no longer available.');
      }
      final location = await transaction.get(
        _db.collection('busLocations').doc(booking['busId']),
      );
      final distance = _metresBetween(booking, location.data());
      if (distance == null || distance > 100) {
        throw StateError(
          'Your bus is not within 100 m of the pickup point yet.',
        );
      }
      final seats = (booking['seats'] as List<dynamic>? ?? const []).map(
        (seat) => seat.toString(),
      );
      transaction.update(bookingRef, {
        'status': 'confirmed',
        'readyToBoard': true,
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      for (final seat in seats) {
        transaction.update(
          _db.collection('seatHolds').doc('${booking['busId']}_$seat'),
          {'status': 'confirmed', 'confirmedAt': FieldValue.serverTimestamp()},
        );
      }
    });
  }

  Future<void> cancelSeatHold(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to cancel a seat hold.');
    await _db.runTransaction((transaction) async {
      final bookingRef = _db.collection('bookings').doc(bookingId);
      final bookingSnapshot = await transaction.get(bookingRef);
      final booking = bookingSnapshot.data();
      if (booking == null ||
          booking['passengerId'] != user.uid ||
          booking['status'] != 'held') {
        throw StateError('Only an active seat hold can be cancelled.');
      }
      transaction.update(bookingRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      for (final seat in (booking['seats'] as List<dynamic>? ?? const [])) {
        transaction.delete(
          _db.collection('seatHolds').doc('${booking['busId']}_$seat'),
        );
      }
    });
  }

  Future<void> submitJourneyRatings({
    required String bookingId,
    required int journeyRating,
    required int driverRating,
    required int busRating,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to submit a rating.');
    if ([
      journeyRating,
      driverRating,
      busRating,
    ].any((rating) => rating < 1 || rating > 5)) {
      throw StateError('Choose between one and five stars for every rating.');
    }
    await _db.collection('bookings').doc(bookingId).update({
      'journeyRating': journeyRating,
      'driverRating': driverRating,
      'busRating': busRating,
      'ratedAt': FieldValue.serverTimestamp(),
    });
  }

  double? _distanceKilometres(Iterable<Map<String, dynamic>> stops) {
    final points = stops
        .map((stop) => _point(stop['latitude'], stop['longitude']))
        .toList();
    if (points.any((point) => point == null)) return null;
    var metres = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      metres += const Distance().as(
        LengthUnit.Meter,
        points[index - 1]!,
        points[index]!,
      );
    }
    return metres / 1000;
  }

  double? _metresBetween(
    Map<String, dynamic> booking,
    Map<String, dynamic>? location,
  ) {
    final pickup = _point(
      booking['pickupLatitude'],
      booking['pickupLongitude'],
    );
    final bus = _point(
      location?['currentLatitude'] ?? location?['latitude'],
      location?['currentLongitude'] ?? location?['longitude'],
    );
    if (pickup == null || bus == null) return null;
    return const Distance().as(LengthUnit.Meter, pickup, bus);
  }

  LatLng? _point(dynamic latitude, dynamic longitude) =>
      latitude is num && longitude is num
      ? LatLng(latitude.toDouble(), longitude.toDouble())
      : null;

  /// Compatibility entry point for any legacy caller. New UI callers collect
  /// the destination and MoMo number before creating a hold.
  Future<void> reserveSeats({
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
    required String busId,
    required String routeId,
    required List<String> seats,
    required int farePerSeat,
<<<<<<< HEAD
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to reserve a seat.');
    final busRef = _db.collection('buses').doc(busId);
    final bookingRef = _db.collection('bookings').doc();
    final reservationRef = _db.collection('seatReservations').doc();
    await _db.runTransaction((transaction) async {
      final bus = await transaction.get(busRef);
      final taken = List<String>.from(bus.data()?['reservedSeats'] ?? const []);
      if (seats.any(taken.contains)) {
        throw StateError('One or more selected seats are no longer available.');
      }
      transaction.set(busRef, {
        'reservedSeats': [...taken, ...seats],
      }, SetOptions(merge: true));
      transaction.set(bookingRef, {
        'passengerId': user.uid,
        'busId': busId,
        'routeId': routeId,
        'seats': seats,
        'fare': farePerSeat * seats.length,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
        if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
      });
      transaction.set(reservationRef, {
        'bookingId': bookingRef.id,
        'busId': busId,
        'seats': seats,
        'status': 'reserved',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return bookingRef.id;
=======
    required String destinationStopId,
    required String momoPhone,
  }) async {
    await createSeatHold(
      busId: busId,
      routeId: routeId,
      seats: seats,
      destinationStopId: destinationStopId,
      momoPhone: momoPhone,
    );
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  }

  Future<void> updateBusLocation({
    required String busId,
    required double latitude,
    required double longitude,
    required String status,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('busLocations').doc(busId), {
      'latitude': latitude,
      'longitude': longitude,
      'currentLatitude': latitude,
      'currentLongitude': longitude,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('buses').doc(busId), {
      'currentLatitude': latitude,
      'currentLongitude': longitude,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
