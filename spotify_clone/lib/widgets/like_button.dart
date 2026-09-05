import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class LikeButton extends StatelessWidget {
  final String songId;
  final double size;

  const LikeButton({super.key, required this.songId, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Icon(Icons.favorite_border, size: size);

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Icon(Icons.favorite_border, color: Colors.white, size: size);
        }

        List likedSongs = (snapshot.data!.data() as Map<String, dynamic>)['likedSongs'] ?? [];
        bool isLiked = likedSongs.contains(songId);

        return GestureDetector(
          onTap: () {
            if (isLiked) {
              userDoc.update({'likedSongs': FieldValue.arrayRemove([songId])});
            } else {
              userDoc.update({'likedSongs': FieldValue.arrayUnion([songId])});
            }
          },
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? AppColors.primaryGreen : Colors.white,
            size: size,
          ),
        );
      },
    );
  }
}
