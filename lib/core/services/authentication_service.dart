import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  AuthenticationService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> updateProfile({String? name, String? photoUrl}) =>
      _auth.currentUser?.updateProfile(displayName: name, photoURL: photoUrl) ??
      Future.value();

  Future<void> signOut() {
    return _auth.signOut();
  }
}
