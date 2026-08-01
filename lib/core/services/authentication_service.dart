import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthenticationService {
  AuthenticationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _requestTimeout = Duration(seconds: 20);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the workspace assigned to the signed-in account. Accounts with
  /// no recognised role are passengers by default.
  Future<String> roleForUser(User user) async {
    final data = (await _withTimeout(
      _db.collection('users').doc(user.uid).get(),
      'Checking your account',
    )).data();
    final role = data?['role']?.toString().trim().toLowerCase();
    return switch (role) {
      'admin' => 'admin',
      'driver' => 'driver',
      _ => 'passenger',
    };
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail(
    String email,
    String password, {
    String? role,
  }) async {
    final credential = await _withTimeout(
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password),
      'Signing in',
    );

    if (role != null && role != 'passenger') {
      final userDoc = await _withTimeout(
        _db.collection('users').doc(credential.user!.uid).get(),
        'Checking operator access',
      );
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
<<<<<<< HEAD
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
=======
    if (role != 'passenger') {
      final invite = await _withTimeout(
        _db.collection('operatorIds').doc('${role}_${employeeId.trim()}').get(),
        'Verifying your employee ID',
      );
      if (invite.data()?['approved'] != true ||
          invite.data()?['role'] != role) {
        throw StateError(
          'Employee ID verification failed. Please use a valid approved ID.',
        );
      }
    }

    final credential = await _withTimeout(
      _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
      'Creating your account',
    );

    await _withTimeout(
      _db.collection('users').doc(credential.user!.uid).set({
        'email': email.trim(),
        'role': role,
        'employeeId': role == 'passenger' ? '' : employeeId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'Saving your account',
    );
    if (role == 'driver') {
      await _withTimeout(
        _db.collection('drivers').doc(credential.user!.uid).set({
          'userId': credential.user!.uid,
          'email': email.trim(),
          'employeeId': employeeId.trim(),
          'status': 'offline',
          'createdAt': FieldValue.serverTimestamp(),
        }),
        'Setting up your driver profile',
      );
    }
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

    return credential;
  }

  /// Claims the one-time passenger welcome notification for this account.
  /// A transaction prevents it from being shown again on later sign-ins.
  Future<bool> claimWelcomeNotification() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    final userRef = _db.collection('users').doc(user.uid);
    var claimed = false;
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null || data['role'] != 'passenger') {
        return;
      }
      if (data['welcomeNotificationSentAt'] != null) return;
      transaction.update(userRef, {
        'welcomeNotificationSentAt': FieldValue.serverTimestamp(),
      });
      claimed = true;
    });
    return claimed;
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
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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

  Future<T> _withTimeout<T>(
    Future<T> request,
    String action,
  ) => request.timeout(
    _requestTimeout,
    onTimeout: () => throw TimeoutException(
      '$action took too long. Check your internet connection and try again.',
    ),
  );
}
