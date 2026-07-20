import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> reserveSeats({
    required String busId,
    required String routeId,
    required List<String> seats,
    required int farePerSeat,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to reserve a seat.');
    await _db.runTransaction((transaction) async {
      final busRef = _db.collection('buses').doc(busId);
      final bus = await transaction.get(busRef);
      final taken = List<String>.from(bus.data()?['reservedSeats'] ?? const []);
      if (seats.any(taken.contains)) {
        throw StateError('One or more selected seats are no longer available.');
      }
      final bookingRef = _db.collection('bookings').doc();
      final reservationRef = _db.collection('seatReservations').doc();
      transaction.update(busRef, {
        'reservedSeats': [...taken, ...seats],
      });
      transaction.set(bookingRef, {
        'passengerId': user.uid,
        'busId': busId,
        'routeId': routeId,
        'seats': seats,
        'fare': farePerSeat * seats.length,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
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
  }

  Future<void> updateBusLocation({
    required String busId,
    required double latitude,
    required double longitude,
    required String status,
  }) => _db.collection('busLocations').doc(busId).set({
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
