import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Singleton instance so we can use AuthService.instance everywhere
  static final AuthService instance = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Get the current user ID if someone is logged in
  String get currentUserId {
    return _auth.currentUser?.uid ?? "";
  }

  // 2. Login User
  Future<User?> login(String email, String password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 3. Register User & Save Profile Details
  Future<User?> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String phone,
  ) async {
    try {
      // Create account in Firebase Auth
      var result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;
      // Save user details to Firestore Database
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'firstName': firstName, 'lastName': lastName, 'phone': phone, 'email': email.trim(), 'uid': user.uid, 'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print("Registration Error: $e");
      return null;
    }
  }

  // 4. Send Password Reset Email
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true; // Success
    } catch (e) {
      print("Reset Password Error: $e");
      return false; // Failed
    }
  }

  // 5. Logout User
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
