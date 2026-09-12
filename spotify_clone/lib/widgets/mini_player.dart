import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../services/player_service.dart';
import '../screens/now_playing_screen.dart';
import '../services/audio_handler.dart';
import '../models/music_track.dart';
import '../services/playlist_service.dart';
import '../themes/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlayerService();

    // Check if handler is initialized to prevent crash on startup
    try {
      audioHandler.playbackState;
    } catch (e) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<String?>(
      valueListenable: player.currentSongTitle,
      builder: (context, title, child) {
        if (title == null) return const SizedBox.shrink();

        return ValueListenableBuilder<Color>(
          valueListenable: player.miniPlayerBgColor,
          builder: (context, bgColor, _) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NowPlayingScreen(),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 65, // Standard height for MUSIKI
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // 1. DYNAMIC IMAGE RENDERING (Fixes Placeholder issue)
                          ValueListenableBuilder<String?>(
                            valueListenable: player.currentImageUrl,
                            builder: (context, url, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: (url != null && url.isNotEmpty)
                                    ? Image.network(
                                        url,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            _placeholderArt(),
                                      )
                                    : _placeholderArt(),
                              );
                            },
                          ),
                          const SizedBox(width: 12),

                          // 2. SONG INFO
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                ValueListenableBuilder<String?>(
                                  valueListenable: player.currentArtist,
                                  builder: (context, artist, _) => Text(
                                    artist ?? "Unknown Artist",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ValueListenableBuilder<MusicTrack?>(
                            valueListenable: player.currentTrack,
                            builder: (context, track, _) {
                              return IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: track == null
                                    ? null
                                    : () async {
                                        await PlaylistService().addSongToLiked(
                                          track,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  AppColors.surfaceHigh,
                                              content: Text(
                                                "Added \"${track.title}\" to Liked Songs",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              );
                            },
                          ),

                          // 3. INSTANT PLAY/PAUSE SYNC (Fixes lag and completion issue)
                          StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState.stream,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return IconButton(
                                onPressed: () => player.togglePlay(),
                                icon: Icon(
                                  playing
                                      ? Icons.pause
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // 4. PROGRESS BAR
                    Positioned(
                      bottom: 0,
                      left: 12,
                      right: 12,
                      child: StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: player.durationStream,
                            builder: (context, snapshot) {
                              final duration = snapshot.data ?? Duration.zero;
                              double progress = 0.0;
                              if (duration.inMilliseconds > 0) {
                                progress =
                                    position.inMilliseconds /
                                    duration.inMilliseconds;
                              }
                              return Container(
                                height: 2,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(color: Colors.white),
                                ),
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
      },
    );
  }

  // Fallback if image fails to load
  Widget _placeholderArt() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.white10,
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }
}
