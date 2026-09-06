import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Add this import
import '../themes/app_colors.dart';
import '../services/player_service.dart';
import '../widgets/like_button.dart';

class NowPlayingScreen extends StatefulWidget { // Changed to StatefulWidget for flicker logic
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  // Temporary colors for the flicker effect
  Color _prevColor = Colors.white;
  Color _nextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final player = PlayerService();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Increased height
        child: Padding(
          padding: const EdgeInsets.only(top: 40), // LOWERED THE UI AS REQUESTED
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("NOW PLAYING",
                style: TextStyle(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            centerTitle: true,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: Colors.white)),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // 1. LARGE CINEMATIC ARTWORK
            ValueListenableBuilder<String?>(
              valueListenable: player.currentImageUrl,
              builder: (context, imageUrl, _) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceHigh, child: const Icon(Icons.music_note, size: 100)),
                  ),
                );
              },
            ),

            const Spacer(flex: 1),

            // 2. SONG & ARTIST INFO + LIKE BUTTON LOGIC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: player.currentSongTitle,
                        builder: (context, title, _) => Text(
                          title ?? "Select a Song",
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: player.currentArtist,
                        builder: (context, artist, _) => Text(
                          artist ?? "",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // REUSABLE LIKE BUTTON LOGIC
                ValueListenableBuilder<String?>(
                  valueListenable: player.currentSongId,
                  builder: (context, id, _) => id != null ? LikeButton(songId: id) : const SizedBox(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 3. PROGRESS BAR (STAYING AS IS)
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: player.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primaryGreen,
                            inactiveTrackColor: Colors.white10,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble(),
                            max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                            onChanged: (value) => player.seek(Duration(seconds: value.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              Text(_formatDuration(duration), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // 4. MAIN PLAYBACK CONTROLS + LOGIC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SHUFFLE BUTTON
                ValueListenableBuilder<bool>(
                  valueListenable: player.isShuffle,
                  builder: (context, shuffle, _) => IconButton(
                    onPressed: () => player.toggleShuffle(),
                    icon: Icon(Icons.shuffle, color: shuffle ? AppColors.primaryGreen : AppColors.textMuted, size: 28),
                  ),
                ),

                // PREVIOUS BUTTON (Flicker logic)
                IconButton(
                  onPressed: () {
                    setState(() => _prevColor = AppColors.primaryGreen);
                    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _prevColor = Colors.white));
                    player.skipPrevious();
                  },
                  icon: Icon(Icons.skip_previous_rounded, color: _prevColor, size: 45),
                ),

                // CIRCULAR PLAY/PAUSE (CORE DESIGN)
                ValueListenableBuilder<bool>(
                  valueListenable: player.isPlaying,
                  builder: (context, playing, _) => GestureDetector(
                    onTap: () => player.togglePlay(),
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 45),
                    ),
                  ),
                ),

                // NEXT BUTTON (Flicker logic)
                IconButton(
                  onPressed: () {
                    setState(() => _nextColor = AppColors.primaryGreen);
                    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _nextColor = Colors.white));
                    player.skipNext();
                  },
                  icon: Icon(Icons.skip_next_rounded, color: _nextColor, size: 45),
                ),

                // REPEAT BUTTON
                ValueListenableBuilder<LoopMode>(
                  valueListenable: player.loopMode,
                  builder: (context, mode, _) => IconButton(
                    onPressed: () => player.toggleRepeat(),
                    icon: Icon(Icons.repeat, color: mode == LoopMode.one ? AppColors.primaryGreen : AppColors.textMuted, size: 28),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 2),

            // 5. LYRICS BUTTON
            const Text("LYRICS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
