import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/osrm_routing_service.dart';

class TripFareQuote {
  const TripFareQuote({
    required this.pickupStopId,
    required this.pickupStopName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationStopId,
    required this.destinationStopName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.farePerSeat,
    required this.distanceKm,
  });

  final String pickupStopId;
  final String pickupStopName;
  final num pickupLatitude;
  final num pickupLongitude;
  final String destinationStopId;
  final String destinationStopName;
  final num destinationLatitude;
  final num destinationLongitude;
  final int farePerSeat;
  final double distanceKm;
}

/// A real-time summary of booking documents stored in Firestore.
class BookingBreakdown {
  const BookingBreakdown(this.counts);

  final Map<String, int> counts;

  int get total => counts.values.fold(0, (total, value) => total + value);

  int operator [](String status) => counts[status] ?? 0;

  static BookingBreakdown fromDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final counts = <String, int>{
      'held': 0,
      'confirmed': 0,
      'active': 0,
      'boarding': 0,
      'boarded': 0,
      'completed': 0,
      'cancelled': 0,
    };
    for (final document in documents) {
      final status = document.data()['status']?.toString().trim().toLowerCase();
      if (status != null && counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return BookingBreakdown(Map.unmodifiable(counts));
  }
}

/// Road-route arrival estimates for one passenger booking. Both values count
/// from the bus's current live location, so the destination ETA includes the
/// time needed to reach the selected pickup first.
class BookingTripEta {
  const BookingTripEta({
    required this.pickupMinutes,
    required this.destinationMinutes,
  });

  final int pickupMinutes;
  final int destinationMinutes;
}

class TransitRepository {
  TransitRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    OsrmRoutingService? routing,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _routing = routing ?? OsrmRoutingService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final OsrmRoutingService _routing;

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

  Stream<BookingBreakdown> liveBookingBreakdown() => _db
      .collection('bookings')
      .snapshots()
      .map((snapshot) => BookingBreakdown.fromDocuments(snapshot.docs));

  Future<String> createSeatHold({
    required String busId,
    required String routeId,
    required List<String> seats,
    required String pickupStopId,
    required String destinationStopId,
    required String momoPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to hold a seat.');
    if (seats.isEmpty || seats.length > 8) {
      throw StateError('Choose between one and eight seats.');
    }
    final quote = await quoteFare(
      routeId: routeId,
      pickupStopId: pickupStopId,
      destinationStopId: destinationStopId,
    );
    final routeSnapshot = await _db.collection('routes').doc(routeId).get();
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
        'pickupStopId': quote.pickupStopId,
        'pickupStopName': quote.pickupStopName,
        'pickupLatitude': quote.pickupLatitude,
        'pickupLongitude': quote.pickupLongitude,
        'destinationStopId': quote.destinationStopId,
        'destinationStopName': quote.destinationStopName,
        'destinationLatitude': quote.destinationLatitude,
        'destinationLongitude': quote.destinationLongitude,
        'seats': seats,
        'fareType': 'fixed_route',
        'distanceKm': quote.distanceKm,
        'distanceSource': 'road_route',
        'farePerSeat': quote.farePerSeat,
        'fare': quote.farePerSeat * seats.length,
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

  /// Calculates live road-route ETAs from the published bus GPS position to
  /// the passenger's pickup and then their destination stop.
  Future<BookingTripEta> estimateBookingEta({
    required Map<String, dynamic> booking,
    required Map<String, dynamic>? location,
  }) async {
    final bus = _point(
      location?['currentLatitude'] ?? location?['latitude'],
      location?['currentLongitude'] ?? location?['longitude'],
    );
    final pickup = _point(
      booking['pickupLatitude'],
      booking['pickupLongitude'],
    );
    var destination = _point(
      booking['destinationLatitude'],
      booking['destinationLongitude'],
    );
    if (bus == null || pickup == null) {
      throw StateError('Waiting for the bus location and pickup coordinates.');
    }
    if (destination == null) {
      final routeId = booking['routeId']?.toString();
      final stopId = booking['destinationStopId']?.toString();
      if (routeId == null ||
          routeId.isEmpty ||
          stopId == null ||
          stopId.isEmpty) {
        throw StateError('The destination stop is unavailable.');
      }
      final stop = await _db
          .collection('routes')
          .doc(routeId)
          .collection('stops')
          .doc(stopId)
          .get();
      final data = stop.data();
      destination = _point(
        data?['latitude'] ?? data?['lat'],
        data?['longitude'] ?? data?['lng'],
      );
    }
    if (destination == null) {
      throw StateError('The destination stop needs map coordinates.');
    }
    final route = await _routing.routeThrough([bus, pickup, destination]);
    if (route.legDurations.length < 2) {
      throw StateError('The road route did not include both journey legs.');
    }
    final pickupMinutes = _etaMinutes(route.legDurations.first);
    final destinationMinutes = _etaMinutes(
      route.legDurations
          .take(2)
          .fold(Duration.zero, (total, leg) => total + leg),
    );
    return BookingTripEta(
      pickupMinutes: pickupMinutes,
      destinationMinutes: destinationMinutes,
    );
  }

  /// Quotes a trip over the same road path used to display the route map.
  /// Every configured point between the selected pickup and stop is supplied
  /// to OSRM, so the distance follows the assigned route rather than a direct
  /// line between the two places.
  Future<TripFareQuote> quoteFare({
    required String routeId,
    required String pickupStopId,
    required String destinationStopId,
  }) async {
    final routeSnapshot = await _db.collection('routes').doc(routeId).get();
    if (!routeSnapshot.exists) {
      throw StateError('The selected route is unavailable.');
    }
    final stopsSnapshot = await routeSnapshot.reference
        .collection('stops')
        .get();
    final stops = stopsSnapshot.docs.toList()
      ..sort(
        (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
          (b.data()['order'] as num?)?.toInt() ?? 99999,
        ),
      );
    if (stops.length < 2) {
      throw StateError('This route needs a pickup point and a stop.');
    }
    final pickupIndex = stops.indexWhere((stop) => stop.id == pickupStopId);
    final destinationIndex = stops.indexWhere(
      (stop) => stop.id == destinationStopId,
    );
    if (pickupIndex < 0 || destinationIndex <= pickupIndex) {
      throw StateError('Choose a stop after your pickup point.');
    }
    final pickup = stops[pickupIndex].data();
    final destination = stops[destinationIndex].data();
    if (!_isRoutePoint(pickup) || !_isRoutePoint(destination)) {
      throw StateError('Choose points configured on this route.');
    }
    // Every journey must have an administrator-set fare for its exact ordered
    // pickup/stop pair. Road distance is retained for the map and ETA only.
    final fareConfiguration = await _db
        .collection('fares')
        .doc(_fareConfigurationId(routeId, pickupStopId, destinationStopId))
        .get();
    final configuredFare = _number(fareConfiguration.data()?['farePerSeat']);
    if (configuredFare == null || configuredFare <= 0) {
      throw StateError(
        'The administrator has not set a fare for this pickup and stop yet.',
      );
    }
    final points = stops
        .sublist(pickupIndex, destinationIndex + 1)
        .map(
          (stop) => _point(
            stop.data()['latitude'] ?? stop.data()['lat'],
            stop.data()['longitude'] ?? stop.data()['lng'],
          ),
        )
        .toList();
    if (points.any((point) => point == null)) {
      throw StateError(
        'All route points between this pickup and stop need map coordinates.',
      );
    }
    try {
      final roadRoute = await _routing.routeThrough(points.cast<LatLng>());
      if (roadRoute.distanceMetres <= 0) {
        throw StateError('No road distance was returned for this trip.');
      }
      return TripFareQuote(
        pickupStopId: stops[pickupIndex].id,
        pickupStopName: pickup['name']?.toString() ?? 'Pickup point',
        pickupLatitude: _number(pickup['latitude'] ?? pickup['lat'])!,
        pickupLongitude: _number(pickup['longitude'] ?? pickup['lng'])!,
        destinationStopId: stops[destinationIndex].id,
        destinationStopName: destination['name']?.toString() ?? 'Stop',
        destinationLatitude: _number(
          destination['latitude'] ?? destination['lat'],
        )!,
        destinationLongitude: _number(
          destination['longitude'] ?? destination['lng'],
        )!,
        farePerSeat: configuredFare.round(),
        distanceKm: roadRoute.distanceMetres / 1000,
      );
    } catch (_) {
      throw StateError(
        'The road route could not be calculated. Check your internet connection and try again.',
      );
    }
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

  bool _isRoutePoint(Map<String, dynamic> stop) {
    final type = stop['type']?.toString().trim().toLowerCase();
    return type == 'pickup' ||
        type == 'pickup_point' ||
        type == 'pickup point' ||
        type == 'stop' ||
        type == 'destination' ||
        type == 'both';
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

  LatLng? _point(dynamic latitude, dynamic longitude) {
    final lat = _number(latitude);
    final lng = _number(longitude);
    return lat == null || lng == null
        ? null
        : LatLng(lat.toDouble(), lng.toDouble());
  }

  num? _number(dynamic value) => value is num ? value : num.tryParse('$value');

  int _etaMinutes(Duration duration) =>
      (duration.inSeconds / 60).ceil().clamp(0, 24 * 60).toInt();

  String _fareConfigurationId(
    String routeId,
    String pickupStopId,
    String destinationStopId,
  ) => '${routeId}_${pickupStopId}_$destinationStopId';

  /// Compatibility entry point for callers that collect the trip before a
  /// hold is created.
  Future<void> reserveSeats({
    required String busId,
    required String routeId,
    required List<String> seats,
    required int farePerSeat,
    required String pickupStopId,
    required String destinationStopId,
    required String momoPhone,
  }) async {
    await createSeatHold(
      busId: busId,
      routeId: routeId,
      seats: seats,
      pickupStopId: pickupStopId,
      destinationStopId: destinationStopId,
      momoPhone: momoPhone,
    );
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
