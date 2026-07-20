import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  ReportService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Future<void> createReport({
    required DateTime start,
    required DateTime end,
    required String type,
  }) async {
    final results = await Future.wait([
      _db
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get(),
      _db
          .collection('trips')
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startedAt', isLessThan: Timestamp.fromDate(end))
          .get(),
      _db
          .collection('payments')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get(),
      _db
          .collection('seatReservations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get(),
    ]);
    final payments = results[2].docs.map((d) => d.data());
    final revenue = payments.fold<num>(
      0,
      (sum, payment) => sum + ((payment['amount'] as num?) ?? 0),
    );
    await _db.collection('reports').add({
      'type': type,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'bookings': results[0].size,
      'trips': results[1].size,
      'payments': results[2].size,
      'seatReservations': results[3].size,
      'revenue': revenue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
