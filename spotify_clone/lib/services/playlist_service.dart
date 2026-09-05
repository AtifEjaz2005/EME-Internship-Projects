import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

   Future<void> deletePlaylist(String playlistId) async {
    String uid = _auth.currentUser!.uid;

    // 1. Reference to the playlist document
    DocumentReference playlistRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId);

    try {
      // 2. Get all songs inside this specific playlist's sub-collection
      var songsSnapshot = await playlistRef.collection('songs').get();

      // 3. Delete every song document in that sub-collection
      for (var doc in songsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 4. Finally, delete the playlist document itself
      await playlistRef.delete();

      debugPrint("Playlist and internal songs deleted permanently.");
    } catch (e) {
      debugPrint("Error deleting playlist: $e");
    }
  }
}
