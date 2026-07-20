import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  AuthenticationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail(
    String email,
    String password, {
    String? role,
    String? employeeId,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (role != null && role != 'passenger') {
      final userDoc = await _db
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      final data = userDoc.data();
      if (data == null ||
          data['role'] != role ||
          data['employeeId'] != employeeId?.trim()) {
        await _auth.signOut();
        throw StateError(
          'Operator sign-in failed. Please check your role and employee ID.',
        );
      }
    }

    return credential;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String role,
    required String employeeId,
  }) async {
    if (role != 'passenger') {
      final matching = await _db
          .collection('operatorIds')
          .where('role', isEqualTo: role)
          .where('employeeId', isEqualTo: employeeId.trim())
          .where('approved', isEqualTo: true)
          .limit(1)
          .get();

      if (matching.docs.isEmpty) {
        throw StateError(
          'Employee ID verification failed. Please use a valid approved ID.',
        );
      }
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'email': email.trim(),
      'role': role,
      'employeeId': role == 'passenger' ? '' : employeeId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<void> updateProfile({String? name, String? photoUrl}) =>
      _auth.currentUser?.updateProfile(displayName: name, photoURL: photoUrl) ??
      Future.value();

  Future<void> signOut() {
    return _auth.signOut();
  }
}
