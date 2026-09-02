import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final bool isLikedSongs;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    this.isLikedSongs = false
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView( // Using Slivers for a premium scrolling effect
        slivers: [
          // 1. DYNAMIC HEADER
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isLikedSongs ? const Color(0xFF2E4E3B) : const Color(0xFF222326),
                      AppColors.primaryBackground,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Large Playlist Icon
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
                      ),
                      child: Icon(
                        isLikedSongs ? Icons.favorite : Icons.music_note,
                        size: 80,
                        color: isLikedSongs ? AppColors.primaryGreen : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      playlistName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. ACTION ROW (Play, Like, Download)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Veyra Mixtape", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("24 songs • 2h 30m", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                  const SizedBox(width: 20),
                  const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 20),
                  // GREEN PLAY BUTTON
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryGreen,
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 35),
                  ),
                ],
              ),
            ),
          ),

          // 3. TRACKLIST (Mock data for now)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50, height: 50, color: Colors.white10,
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                  title: Text("Track ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  subtitle: const Text("Veyra Artist", style: TextStyle(color: AppColors.textMuted)),
                  trailing: const Icon(Icons.more_vert, color: Colors.white70),
                );
              },
              childCount: 15,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for MiniPlayer
        ],
      ),
    );
  }
}
