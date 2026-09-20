import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../services/player_service.dart';
import '../services/lyrics_service.dart';

class LyricsSheet extends StatefulWidget {
  final String title;
  final String artist;

  const LyricsSheet({super.key, required this.title, required this.artist});

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  late Future<Map<String, dynamic>?> _lyricsFuture;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    final duration = PlayerService().currentTrack.value?.duration?.inSeconds;
    _lyricsFuture = LyricsService().fetchLyrics(
      trackName: widget.title,
      artistName: widget.artist,
      durationSeconds: duration,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll(int activeIndex) {
    if (activeIndex != _lastActiveIndex && _scrollController.hasClients) {
      _lastActiveIndex = activeIndex;
      final targetOffset = (activeIndex * 55.0) - 150.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF161818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.artist,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),

          // Content
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _lyricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                final data = snapshot.data;
                final List<LyricsLine>? synced = data?['synced'];
                final String? plain = data?['plain'];

                if (synced == null && (plain == null || plain.isEmpty)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "Lyrics not available for this track.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),
                  );
                }

                // A. SYNCHRONIZED TIMED LYRICS
                if (synced != null && synced.isNotEmpty) {
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, posSnapshot) {
                      final currentPos = posSnapshot.data ?? Duration.zero;

                      // Find active line
                      int activeIndex = -1;
                      for (int i = 0; i < synced.length; i++) {
                        if (currentPos >= synced[i].timestamp) {
                          activeIndex = i;
                        } else {
                          break;
                        }
                      }

                      _autoScroll(activeIndex);

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: synced.length,
                        itemBuilder: (context, index) {
                          final isCurrent = index == activeIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isCurrent ? 20 : 16,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? AppColors.primaryGreen : Colors.white38,
                                height: 1.4,
                              ),
                              child: Text(synced[index].text),
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                // B. PLAIN SCROLLABLE LYRICS (Fallback if synced not available)
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    plain!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
