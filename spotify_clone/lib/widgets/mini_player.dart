import 'package:flutter/material.dart';
import '../services/player_service.dart';
import '../screens/now_playing_screen.dart';
import '../services/audio_handler.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlayerService();

    try {
      // If this line fails, it means audioHandler is not ready
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
                height: 65,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                // We use ClipRRect here so the progress bar at the bottom respects the corners
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  // Added Stack to place the progress bar at the bottom
                  children: [
                    // 1. THE MAIN CONTENT (Row with info and buttons)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                          const Icon(
                            Icons.devices_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          ValueListenableBuilder<bool>(
                            valueListenable: player.isPlaying,
                            builder: (context, isPlaying, _) {
                              return IconButton(
                                onPressed: () => player.togglePlay(),
                                icon: Icon(
                                  isPlaying
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

                    // 2. THE PROGRESS BAR (The "Missing" UI)
                    Positioned(
                      bottom: 0,
                      left: 12, // Match the padding of the content
                      right: 12,
                      child: StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: player.durationStream,
                            builder: (context, snapshot) {
                              final duration = snapshot.data ?? Duration.zero;

                              // Calculate percentage of song played
                              double progress = 0.0;
                              if (duration.inMilliseconds > 0) {
                                progress =
                                    position.inMilliseconds /
                                    duration.inMilliseconds;
                              }

                              return Container(
                                height: 2, // Very thin line
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white24, // Background of the bar
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    color: Colors.white, // The "Played" part
                                  ),
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
}
