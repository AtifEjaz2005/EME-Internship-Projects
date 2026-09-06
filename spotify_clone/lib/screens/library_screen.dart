import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/app_colors.dart';
import '../services/playlist_service.dart';
import 'playlist_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Your Library",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white)),
        ],
      ),
      body: Column(
        children: [
          // 1. FILTER CHIPS (Design Spec #16)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: "Playlists"),
                  SizedBox(width: 8),
                  _FilterChip(label: "Artists"),
                  SizedBox(width: 8),
                  _FilterChip(label: "Albums"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. LIBRARY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>( // Changed to QuerySnapshot to get IDs
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('playlists')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // A. LIKED SONGS (Fixed, no delete option)
                    _buildLibraryItem(
                      context,
                      title: "Liked Songs",
                      subtitle: "Playlist",
                      isLiked: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const PlaylistDetailScreen(playlistName: "Liked Songs", isLikedSongs: true)
                      )),
                    ),

                    // B. DYNAMIC PLAYLISTS WITH DELETE OPTION
                    ...docs.map((doc) {
                      String name = doc['name'];
                      String id = doc.id; // We need this ID to delete it

                      return _buildLibraryItem(
                        context,
                        title: name,
                        subtitle: "Playlist • MUSIKI User",
                        playlistId: id, // Pass ID for the delete menu
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlistName: name)
                        )),
                      );
                    }),

                    const SizedBox(height: 120),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(BuildContext context, {
    required String title,
    required String subtitle,
    bool isLiked = false,
    String? playlistId, // Optional ID
    required VoidCallback onTap
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: AppColors.surfaceDefault,
          gradient: isLiked ? const LinearGradient(colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)]) : null,
        ),
        child: Center(
          child: isLiked
            ? const Icon(Icons.favorite, color: Colors.white)
            : SvgPicture.asset('lib/assets/library.svg', width: 24, colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn)),
        ),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),

      // THREE DOTS DROPDOWN MENU
      trailing: isLiked ? null : PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        color: AppColors.surfaceHigh,
        onSelected: (value) {
          if (value == 'delete') {
            _showDeleteConfirmation(context, playlistId!, title);
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 10),
                Text("Delete Playlist", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation Alert (Matches your Veyra/MUSIKI notification style)
  void _showDeleteConfirmation(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDefault,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text("Delete '$name'?", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("This will permanently remove the playlist and all songs inside it.",
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () async {
                    await PlaylistService().deletePlaylist(id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
