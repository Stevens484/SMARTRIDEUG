import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
      if (data == null || data['role'] != role) {
        await _auth.signOut();
        throw StateError('Operator sign-in failed. Please check your role.');
      }
    }

    return credential;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'email': email.trim(),
      'role': 'passenger',
      'employeeId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String employeeId,
    required String role,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'staffCreation-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'employeeId': employeeId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> updateProfile({String? name, String? photoUrl}) =>
      _auth.currentUser?.updateProfile(displayName: name, photoURL: photoUrl) ??
      Future.value();

  Future<void> signOut() {
    return _auth.signOut();
  }
}
