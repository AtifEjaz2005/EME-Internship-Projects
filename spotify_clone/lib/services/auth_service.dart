import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to Auth State (Logged In or Out)
  Stream<User?> get user => _auth.authStateChanges();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the picker

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      UserCredential result = await _auth.signInWithCredential(credential);

      // 5. Optional: Create user profile in Firestore if it's their first time
      if (result.additionalUserInfo!.isNewUser) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': result.user!.displayName,
          'email': result.user!.email,
          'createdAt': DateTime.now(),
        });
      }

      return result.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // REGISTER
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create User Profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
      });

      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the actual Firebase error
    }
  }

  // LOGIN
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
