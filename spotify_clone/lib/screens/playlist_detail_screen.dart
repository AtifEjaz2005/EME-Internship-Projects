import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:spotify_clone/services/audio_handler.dart';
import '../themes/app_colors.dart';
import '../services/player_service.dart';
import '../services/playlist_service.dart';
import '../models/music_track.dart';
import '../widgets/song_options_sheet.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final String? playlistId;
  final bool isLikedSongs;
  final List<MusicTrack>? preloadedTracks;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    this.playlistId,
    this.isLikedSongs = false,
    this.preloadedTracks,
  });

  @override
  Widget build(BuildContext context) {
    final playlistService = PlaylistService();

    final Stream<List<MusicTrack>> songsStream = preloadedTracks != null
        ? Stream.value(preloadedTracks!)
        : (isLikedSongs
              ? playlistService.getLikedSongs()
              : (playlistId != null
                    ? playlistService.getPlaylistSongs(playlistId!)
                    : const Stream.empty()));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: StreamBuilder<List<MusicTrack>>(
        stream: songsStream,
        builder: (context, snapshot) {
          final songs = snapshot.data ?? [];

          // DYNAMIC COVER ART: Get the image of the first song in this playlist
          final String? firstSongCover =
              (songs.isNotEmpty && songs.first.artworkUrl.isNotEmpty)
              ? songs.first.artworkUrl
              : null;

          return CustomScrollView(
            slivers: [
              // 1. DYNAMIC HEADER
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primaryBackground,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isLikedSongs
                              ? const Color(0xFF2E4E3B)
                              : const Color(0xFF222326),
                          AppColors.primaryBackground,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // PLAYLIST COVER ARTWORK (Displays 1st song's artwork)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: firstSongCover != null
                                ? Image.network(
                                    firstSongCover,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _buildPlaceholderIcon(),
                                  )
                                : _buildPlaceholderIcon(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          playlistName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. ACTION ROW (WITH FUNCTIONAL GREEN PLAY BUTTON)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        isLikedSongs
                            ? "Favorite Tracks • MUSIKI"
                            : "Playlist • MUSIKI",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      // GREEN PLAY BUTTON: Starts playback with the whole playlist queued
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState.stream,
                        builder: (context, playbackSnapshot) {
                          final bool isEnginePlaying =
                              playbackSnapshot.data?.playing ?? false;

                          return ValueListenableBuilder<String?>(
                            valueListenable: PlayerService().currentSongId,
                            builder: (context, currentId, _) {
                              // Check if the currently playing track belongs to this playlist
                              final bool isCurrentPlaylistActive = songs.any(
                                (s) =>
                                    s.id == currentId ||
                                    s.providerTrackId == currentId,
                              );
                              final bool isPlayingThis =
                                  isEnginePlaying && isCurrentPlaylistActive;

                              return GestureDetector(
                                onTap: () {
                                  if (songs.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "No songs to play in this playlist!",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (isCurrentPlaylistActive) {
                                    // If already playing this playlist -> toggle pause / resume
                                    PlayerService().togglePlay();
                                  } else {
                                    // If not playing this playlist -> start playing from track 1
                                    PlayerService().playTrackFromQueue(
                                      songs,
                                      0,
                                    );
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primaryGreen,
                                  child: Icon(
                                    isPlayingThis
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size: 34,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 3. TRACKLIST
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                )
              else if (songs.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "No songs in this playlist yet.\nSearch and add songs using the (⋮) menu!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = songs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: track.artworkUrl.isNotEmpty
                            ? Image.network(
                                track.artworkUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          showSongOptionsSheet(
                            context: context,
                            track: track,
                            currentPlaylistId: playlistId,
                            currentPlaylistName: playlistName,
                            isLikedSongs: isLikedSongs,
                          );
                        },
                      ),
                      onTap: () =>
                          PlayerService().playTrackFromQueue(songs, index),
                    );
                  }, childCount: songs.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  // Fallback icon widget if the playlist has no songs yet
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        isLikedSongs ? Icons.favorite : Icons.music_note,
        size: 70,
        color: isLikedSongs ? AppColors.primaryGreen : Colors.white,
      ),
    );
  }
}
