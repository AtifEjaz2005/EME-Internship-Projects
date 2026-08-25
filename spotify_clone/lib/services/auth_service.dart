import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // LOGIN LOGIC
  Future<String> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.code; // Returns 'user-not-found', 'wrong-password', etc.
    }
  }

  // FORGOT PASSWORD LOGIC
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create the user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save additional info to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
      });

      // 3. FORCE SIGN OUT immediately
      // This prevents the StreamBuilder in main.dart from jumping to the Home Screen
      await _auth.signOut();

      return "success";
    } on FirebaseAuthException catch (e) {
      // Return specific code for "user exists"
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  // GOOGLE SIGN IN (Assuming your SHA-1 is connected in Firebase Console)
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      print(e);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
