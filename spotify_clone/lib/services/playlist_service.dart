import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/music_track.dart';

class PlaylistModel {
  final String id;
  final String name;

  PlaylistModel({required this.id, required this.name});
}

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // Stream user's playlists with IDs
  Stream<List<PlaylistModel>> getUserPlaylists() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('playlists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlaylistModel(
                  id: doc.id,
                  name: doc['name'] as String,
                ))
            .toList());
  }

  // Legacy helper for backward compatibility
  Stream<List<String>> getPlaylists() {
    return getUserPlaylists().map((list) => list.map((p) => p.name).toList());
  }

  // Create playlist
  Future<void> createPlaylist(String name) async {
    await _firestore.collection('users').doc(_uid).collection('playlists').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete playlist and its songs
  Future<void> deletePlaylist(String playlistId) async {
    DocumentReference playlistRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('playlists')
        .doc(playlistId);

    try {
      var songsSnapshot = await playlistRef.collection('songs').get();
      for (var doc in songsSnapshot.docs) {
        await doc.reference.delete();
      }
      await playlistRef.delete();
    } catch (e) {
      debugPrint("Error deleting playlist: $e");
    }
  }

  // 1. ADD SONG TO A CUSTOM PLAYLIST
  Future<void> addSongToPlaylist({
    required String playlistId,
    required MusicTrack track,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('playlists')
          .doc(playlistId)
          .collection('songs')
          .doc(track.providerTrackId)
          .set({
        ...track.toMap(),
        'addedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Added ${track.title} to playlist $playlistId");
    } catch (e) {
      debugPrint("Error adding song to playlist: $e");
      rethrow;
    }
  }

  // 2. ADD SONG TO LIKED SONGS
  Future<void> addSongToLiked(MusicTrack track) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('liked_songs')
          .doc(track.providerTrackId)
          .set({
        ...track.toMap(),
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Also maintain the ID in user doc array for the LikeButton toggle
      await _firestore.collection('users').doc(_uid).update({
        'likedSongs': FieldValue.arrayUnion([track.providerTrackId]),
      });
      debugPrint("Added ${track.title} to Liked Songs");
    } catch (e) {
      debugPrint("Error adding song to liked: $e");
      rethrow;
    }
  }

  // 3. STREAM SONGS FROM A CUSTOM PLAYLIST
  Stream<List<MusicTrack>> getPlaylistSongs(String playlistId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicTrack.fromMap(doc.data()))
            .toList());
  }

  // 4. STREAM SONGS FROM LIKED SONGS
  Stream<List<MusicTrack>> getLikedSongs() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('liked_songs')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicTrack.fromMap(doc.data()))
            .toList());
  }

  // REMOVE SONG FROM A SPECIFIC PLAYLIST
  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('playlists')
          .doc(playlistId)
          .collection('songs')
          .doc(trackId)
          .delete();
      debugPrint("Removed $trackId from playlist $playlistId");
    } catch (e) {
      debugPrint("Error removing song from playlist: $e");
      rethrow;
    }
  }

  // REMOVE SONG FROM LIKED SONGS
  Future<void> removeSongFromLiked(String trackId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('liked_songs')
          .doc(trackId)
          .delete();

      await _firestore.collection('users').doc(_uid).update({
        'likedSongs': FieldValue.arrayRemove([trackId]),
      });
      debugPrint("Removed $trackId from Liked Songs");
    } catch (e) {
      debugPrint("Error removing from liked: $e");
      rethrow;
    }
  }
}
