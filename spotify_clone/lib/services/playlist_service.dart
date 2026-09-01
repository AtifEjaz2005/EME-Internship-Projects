import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to get playlists for the logged-in user in real-time
  Stream<List<String>> getPlaylists() {
    String uid = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .orderBy('createdAt', descending: true) // Newest first
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['name'] as String).toList());
  }

  // Create a playlist in Firebase
  Future<void> createPlaylist(String name) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).collection('playlists').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
