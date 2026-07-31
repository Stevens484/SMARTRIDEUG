import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartrideug/core/models/bus_model.dart';

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

  /// Creates a temporary hold. Confirmed seats are deliberately untouched
  /// until the passenger says they are ready to board.
  Future<String> createPendingBooking({
    required String busId,
    required String routeId,
    required String busNumber,
    required String routeName,
    required String pickupStopId,
    required String pickupStopName,
    required List<String> seats,
    required int farePerSeat,
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
      final busSnapshot = await transaction.get(busRef);
      final bus = _availableBus(busSnapshot, routeId);
      final heldSeats = _stringList(bus['pendingSeats']);
      final reservedSeats = _stringList(bus['reservedSeats']);
      _ensureSeatsAvailable(
        selectedSeats: selectedSeats,
        totalSeats: _totalSeats(bus),
        reservedSeats: reservedSeats,
        heldSeats: heldSeats,
      );

      final updatedHeldSeats = [...heldSeats, ...selectedSeats];
      transaction.update(busRef, {
        'reservedSeats': reservedSeats,
        'pendingSeats': updatedHeldSeats,
        'availableSeats': _availableSeatCount(
          totalSeats: _totalSeats(bus),
          reservedSeats: reservedSeats,
          heldSeats: updatedHeldSeats,
        ),
        'activeBookingId': bookingRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(bookingRef, {
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
  }) => _db.collection('buses').doc(busId).set({
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
