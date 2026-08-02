import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

/// Firestore-backed transit operations. Seat changes are always performed in a
/// transaction so two passengers cannot claim the same seat.
class TransitRepository {
  TransitRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> liveBuses() => _db
      .collection('buses')
      .where(
        'status',
        whereIn: ['active', 'online', 'moving', 'approaching_stop', 'stopped'],
      )
      .snapshots();

  Stream<List<BusModel>> liveBusModels() => liveBuses().map(
    (snapshot) => snapshot.docs
        .map((doc) => BusModel.fromFirestore(doc.id, doc.data()))
        .where(
          (bus) => bus.position.latitude != 0 || bus.position.longitude != 0,
        )
        .toList(),
  );

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
    required String busNumber,
    required String routeName,
    required String pickupStopId,
    required String pickupStopName,
    required List<String> seats,
    required int farePerSeat,
<<<<<<< HEAD
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    final user = _requireUser('create a booking');
    final selectedSeats = _normalizeSeats(seats);
    if (busId.trim().isEmpty ||
        routeId.trim().isEmpty ||
        pickupStopId.trim().isEmpty ||
        pickupStopName.trim().isEmpty) {
      throw ArgumentError('A bus, route, and pickup stop are required.');
    }
    if (farePerSeat < 0) {
      throw ArgumentError.value(
        farePerSeat,
        'farePerSeat',
        'The fare cannot be negative.',
      );
    }

    final busRef = _db.collection('buses').doc(busId.trim());
    final bookingRef = _db.collection('bookings').doc();
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
        'passengerId': user.uid,
        'busId': busRef.id,
        'busNumber': busNumber.trim(),
        'routeId': routeId.trim(),
        'routeName': routeName.trim(),
        'pickupStopId': pickupStopId.trim(),
        'pickupStopName': pickupStopName.trim(),
        'seats': selectedSeats,
        'farePerSeat': farePerSeat,
        'fare': farePerSeat * selectedSeats.length,
        'status': 'pending_confirmation',
        'readyConfirmed': false,
        'arrivalNotifiedAt': null,
        'expiresAt': null,
        'paymentStatus': null,
        'paymentMethod': null,
        'paymentReference': null,
        'ticketToken': null,
        'paidAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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

  /// Opens the two-minute confirmation window exactly once per booking.
  Future<bool> markBusArrived(String bookingId) async {
    final user = _requireUser('track this booking');
    final bookingRef = _db.collection('bookings').doc(bookingId);
    var opened = false;
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingRef);
      final booking = _ownedPendingBooking(snapshot, user.uid);
      if (booking['arrivalNotifiedAt'] != null) return;

      opened = true;
      transaction.update(bookingRef, {
        'arrivalNotifiedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 2)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return opened;
  }

  /// Moves a passenger's temporary hold into the confirmed seat list.
  Future<void> confirmBooking(
    String bookingId, {
    required String paymentReference,
    required String ticketToken,
  }) async {
    final user = _requireUser('confirm a booking');
    final bookingRef = _db.collection('bookings').doc(bookingId);
    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final booking = _ownedPendingBooking(bookingSnapshot, user.uid);
      final expiresAt = booking['expiresAt'];
      if (expiresAt is! Timestamp ||
          !expiresAt.toDate().isAfter(DateTime.now())) {
        throw StateError('This confirmation window has expired.');
      }

      final busId = booking['busId']?.toString() ?? '';
      final busRef = _db.collection('buses').doc(busId);
      final busSnapshot = await transaction.get(busRef);
      final bus = _availableBus(
        busSnapshot,
        booking['routeId']?.toString() ?? '',
      );
      final seats = _normalizeSeats(_stringList(booking['seats']));
      final reservedSeats = _stringList(bus['reservedSeats']);
      final heldSeats = _stringList(bus['pendingSeats']);
      if (seats.any(reservedSeats.contains) ||
          seats.any((seat) => !heldSeats.contains(seat))) {
        throw StateError('One or more held seats are no longer available.');
      }

      final updatedHeldSeats = heldSeats
          .where((seat) => !seats.contains(seat))
          .toList();
      final updatedReservedSeats = [...reservedSeats, ...seats];
      transaction.update(busRef, {
        'pendingSeats': updatedHeldSeats,
        'reservedSeats': updatedReservedSeats,
        'availableSeats': _availableSeatCount(
          totalSeats: _totalSeats(bus),
          reservedSeats: updatedReservedSeats,
          heldSeats: updatedHeldSeats,
        ),
        'activeBookingId': bookingRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(bookingRef, {
        'status': 'confirmed',
        'readyConfirmed': true,
        'paymentStatus': 'paid_simulated',
        'paymentMethod': 'mtn_momo_simulated',
        'paymentReference': paymentReference,
        'ticketToken': ticketToken,
        'paidAt': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cancelling before confirmation only releases the temporary hold.
  Future<void> cancelBooking(String bookingId) =>
      _releasePendingHold(bookingId, status: 'cancelled');

  /// The local two-minute timer uses this method. It is intentionally a no-op
  /// if the passenger has already confirmed or cancelled.
  Future<void> expireBooking(String bookingId) =>
      _releasePendingHold(bookingId, status: 'expired', requireExpiry: true);

  Future<void> _releasePendingHold(
    String bookingId, {
    required String status,
    bool requireExpiry = false,
  }) async {
    final user = _requireUser('update this booking');
    final bookingRef = _db.collection('bookings').doc(bookingId);
    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final booking = _ownedPendingBooking(bookingSnapshot, user.uid);
      if (requireExpiry) {
        final expiresAt = booking['expiresAt'];
        if (expiresAt is! Timestamp ||
            expiresAt.toDate().isAfter(DateTime.now())) {
          return;
        }
      }

      final busId = booking['busId']?.toString() ?? '';
      final busRef = _db.collection('buses').doc(busId);
      final busSnapshot = await transaction.get(busRef);
      final bus = _availableBus(
        busSnapshot,
        booking['routeId']?.toString() ?? '',
      );
      final seats = _normalizeSeats(_stringList(booking['seats']));
      final heldSeats = _stringList(
        bus['pendingSeats'],
      ).where((seat) => !seats.contains(seat)).toList();
      final reservedSeats = _stringList(bus['reservedSeats']);

      transaction.update(busRef, {
        'pendingSeats': heldSeats,
        'availableSeats': _availableSeatCount(
          totalSeats: _totalSeats(bus),
          reservedSeats: reservedSeats,
          heldSeats: heldSeats,
        ),
        'activeBookingId': bookingRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(bookingRef, {
        'status': status,
        if (status == 'cancelled') 'cancelledAt': FieldValue.serverTimestamp(),
        if (status == 'expired') 'expiredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  User _requireUser(String action) {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to $action.');
    return user;
  }

  Map<String, dynamic> _availableBus(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String routeId,
  ) {
    final bus = snapshot.data();
    if (!snapshot.exists || bus == null || bus['disabled'] == true) {
      throw StateError('This bus is no longer available.');
    }
    final assignedRouteId = bus['routeId']?.toString();
    if (assignedRouteId != null && assignedRouteId != routeId) {
      throw StateError('This bus is not assigned to the selected route.');
    }
    return bus;
  }

  Map<String, dynamic> _ownedPendingBooking(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String userId,
  ) {
    final booking = snapshot.data();
    if (!snapshot.exists || booking == null) {
      throw StateError('This booking is no longer available.');
    }
    if (booking['passengerId'] != userId) {
      throw StateError('You cannot update this booking.');
    }
    if (booking['status'] != 'pending_confirmation') {
      throw StateError('This booking can no longer be updated.');
    }
    return booking;
  }

  void _ensureSeatsAvailable({
    required List<String> selectedSeats,
    required int totalSeats,
    required List<String> reservedSeats,
    required List<String> heldSeats,
  }) {
    if (totalSeats <= 0 || selectedSeats.length > totalSeats) {
      throw StateError('This bus does not have enough seats available.');
    }
    if (selectedSeats.any(reservedSeats.contains) ||
        selectedSeats.any(heldSeats.contains)) {
      throw StateError('One or more selected seats are no longer available.');
    }
  }

  int _totalSeats(Map<String, dynamic> bus) =>
      (bus['totalSeats'] as num?)?.toInt() ?? 0;

  int _availableSeatCount({
    required int totalSeats,
    required List<String> reservedSeats,
    required List<String> heldSeats,
  }) => (totalSeats - reservedSeats.length - heldSeats.length).clamp(
    0,
    totalSeats,
  );

  List<String> _normalizeSeats(List<String> seats) {
    final selectedSeats = seats.map((seat) => seat.trim()).toList();
    if (selectedSeats.isEmpty || selectedSeats.any((seat) => seat.isEmpty)) {
      throw ArgumentError('Select at least one seat.');
    }
    if (selectedSeats.toSet().length != selectedSeats.length) {
      throw ArgumentError('Each seat can only be selected once.');
    }
    return selectedSeats;
  }

  List<String> _stringList(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];

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
