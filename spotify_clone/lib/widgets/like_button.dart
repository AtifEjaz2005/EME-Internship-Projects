import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../models/music_track.dart';
import '../services/playlist_service.dart';

class LikeButton extends StatelessWidget {
  final MusicTrack? track;
  final double size;

  const LikeButton({super.key, required this.track, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || track == null) {
      return Icon(Icons.favorite_border, color: Colors.white, size: size);
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        List likedSongs = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          likedSongs = data?['likedSongs'] ?? [];
        }

        final trackId = track!.providerTrackId;
        final bool isLiked = likedSongs.contains(trackId);

        return IconButton(
          onPressed: () async {
            if (isLiked) {
              // REMOVE FROM LIKED
              await PlaylistService().removeSongFromLiked(trackId);
            } else {
              // ADD FULL TRACK METADATA TO LIKED
              await PlaylistService().addSongToLiked(track!);
            }
          },
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? AppColors.primaryGreen : Colors.white,
            size: size,
          ),
        );
      },
    );
  }
}
