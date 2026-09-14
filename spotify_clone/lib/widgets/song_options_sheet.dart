import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../models/music_track.dart';
import '../services/playlist_service.dart';

void showSongOptionsSheet({
  required BuildContext context,
  required MusicTrack track,
  String? currentPlaylistId,
  String? currentPlaylistName,
  bool isLikedSongs = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDefault,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track Preview Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: track.artworkUrl.isNotEmpty
                          ? Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(width: 44, height: 44, color: Colors.white10))
                          : Container(width: 44, height: 44, color: Colors.white10),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),

              // OPTION 1: Remove from Current Playlist
              if (currentPlaylistId != null && currentPlaylistName != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  title: Text("Remove from $currentPlaylistName",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await PlaylistService().removeSongFromPlaylist(
                      playlistId: currentPlaylistId,
                      trackId: track.providerTrackId,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceHigh,
                          content: Text("Removed from $currentPlaylistName",
                              style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    }
                  },
                ),

              // OPTION 1B: Remove from Liked Songs
              if (isLikedSongs)
                ListTile(
                  leading: const Icon(Icons.favorite_border, color: Colors.redAccent),
                  title: const Text("Remove from Liked Songs",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await PlaylistService().removeSongFromLiked(track.providerTrackId);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.surfaceHigh,
                          content: Text("Removed from Liked Songs", style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }
                  },
                ),

              // OPTION 2: Add to another playlist
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppColors.primaryGreen),
                title: const Text("Add to a playlist",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistPicker(context, track);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Sub-sheet to choose which playlist to add to
void _showPlaylistPicker(BuildContext context, MusicTrack track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDefault,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text("Add to...",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(color: Colors.white12),
              // Option to add to Liked Songs
              ListTile(
                leading: const Icon(Icons.favorite, color: AppColors.primaryGreen),
                title: const Text("Liked Songs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () async {
                  await PlaylistService().addSongToLiked(track);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.surfaceHigh,
                        content: Text("Added to Liked Songs", style: TextStyle(color: Colors.white)),
                      ),
                    );
                  }
                },
              ),
              // List of other custom playlists
              Flexible(
                child: StreamBuilder<List<PlaylistModel>>(
                  stream: PlaylistService().getUserPlaylists(),
                  builder: (context, snapshot) {
                    final playlists = snapshot.data ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.queue_music, color: Colors.white70),
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            await PlaylistService().addSongToPlaylist(playlistId: p.id, track: track);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.surfaceHigh,
                                  content: Text("Added to ${p.name}", style: const TextStyle(color: Colors.white)),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
