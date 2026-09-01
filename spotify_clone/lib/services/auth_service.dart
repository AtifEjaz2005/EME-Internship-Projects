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
      // 1. Create the user in Auth (This is working for you)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Attempt to save to Firestore (This is where the 400 happens)
      // We use a timeout so it doesn't spin forever if the network is bad
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'uid': result.user!.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(), // Use server time
          })
          .timeout(const Duration(seconds: 10));

      // 3. Sign out to prevent direct jump to Home
      await _auth.signOut();

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      // If it's a 400 error, we catch it here
      print("Firestore Error: $e");
      return "firestore-error";
    }
  }

  // GOOGLE SIGN IN (Assuming your SHA-1 is connected in Firebase Console)
  Future<void> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Account Picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user closes the picker, stop here
      if (googleUser == null) return;

      // 2. Obtain auth details from the account
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with that credential
      UserCredential result = await _auth.signInWithCredential(credential);

      // 5. Save/Update user in Firestore (Background task)
      _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'uid': result.user!.uid,
            'name': result.user!.displayName,
            'email': result.user!.email,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((e) => print("Firestore Error: $e"));
    } catch (e) {
      print("CRITICAL GOOGLE ERROR: $e");
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  // Logout must also sign out of Google to show the picker next time
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
