import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/app_colors.dart';
import '../services/playlist_service.dart';
import 'playlist_detail_screen.dart';

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
            child: StreamBuilder<List<String>>(
              stream: PlaylistService().getPlaylists(),
              builder: (context, snapshot) {
                final playlists = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // A. SPECIAL LIKED SONGS TILE
                    _buildLibraryItem(
                      context,
                      title: "Liked Songs",
                      subtitle: "Playlist",
                      isLiked: true,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const PlaylistDetailScreen(
                            playlistName: "Liked Songs",
                            isLikedSongs: true
                          )
                        ));
                      },
                    ),

                    // B. DYNAMIC USER PLAYLISTS
                    ...playlists.map((name) => _buildLibraryItem(
                      context,
                      title: name,
                      subtitle: "Playlist • Veyra User",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlistName: name)
                        ));
                      },
                    )),

                    const SizedBox(height: 120), // Space for MiniPlayer
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
    required VoidCallback onTap
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: isLiked ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
          ) : null,
          color: isLiked ? null : AppColors.surfaceDefault,
        ),
        child: Center(
          child: isLiked
            ? const Icon(Icons.favorite, color: Colors.white, size: 28)
            : SvgPicture.asset('lib/assets/library.svg', width: 24, colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn)),
        ),
      ),
      title: Text(title,
        style: TextStyle(color: isLiked ? AppColors.primaryGreen : Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
