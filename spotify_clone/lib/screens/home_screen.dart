import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/app_colors.dart';
import '../widgets/album_card.dart';
import '../services/playlist_service.dart';
import '../services/player_service.dart';
import '../services/audius_provider.dart';
import '../models/music_track.dart';
import 'playlist_detail_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MusicTrack>> _trendingTracksFuture;
  late Future<List<MusicTrack>> _electronicTracksFuture;

  @override
  void initState() {
    super.initState();
    // Cache the futures so they don't reload on every widget rebuild
    _trendingTracksFuture = AudiusProvider().getTrendingTracks(limit: 10);
    _electronicTracksFuture = AudiusProvider().getTrendingTracks(genre: "Electronic", limit: 10);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openFullPlaylist(String title, Future<List<MusicTrack>> future) async {
    final tracks = await future;
    if (mounted && tracks.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailScreen(
            playlistName: title,
            preloadedTracks: tracks,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. HEADER (Logo + Notification with Badge + Profile)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 48,
                    child: Image.asset('lib/assets/wordmark.png', fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        "MUSIKI",
                        style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 30),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryBackground, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        ),
                        icon: const Icon(Icons.account_circle_outlined, color: AppColors.textPrimary, size: 30),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              Text(
                _getGreeting(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),

              // 2. DYNAMIC FIREBASE QUICK ACCESS GRID
              StreamBuilder<List<PlaylistModel>>(
                stream: PlaylistService().getUserPlaylists(),
                builder: (context, snapshot) {
                  final List<PlaylistModel> userPlaylists = snapshot.data ?? [];
                  final List<PlaylistModel> displayPlaylists = userPlaylists.take(4).toList();
                  final int totalCount = displayPlaylists.length + 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final bool isLiked = index == totalCount - 1;
                      final bool isOther = index == totalCount - 2;
                      final bool isUserPlaylist = !isLiked && !isOther;

                      final String name = isLiked
                          ? "Liked Songs"
                          : (isOther
                              ? "Other Playlists"
                              : displayPlaylists[index].name);

                      final String? playlistId = isUserPlaylist ? displayPlaylists[index].id : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistName: name,
                                playlistId: playlistId,
                                isLikedSongs: isLiked,
                              ),
                            ),
                          );
                        },
                        child: _buildQuickAccessTile(
                          name,
                          isUserPlaylist
                              ? 'lib/assets/library.svg'
                              : (isLiked ? Icons.favorite : Icons.playlist_play),
                          isSvg: isUserPlaylist,
                          isGreen: isLiked,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // 3. CAROUSEL 1: LIVE TRENDING TRACKS ("Made For You")
              _buildSectionHeader(
                "Made For You",
                onSeeAll: () => _openFullPlaylist("Made For You", _trendingTracksFuture),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: FutureBuilder<List<MusicTrack>>(
                  future: _trendingTracksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                    }
                    final tracks = snapshot.data ?? [];
                    if (tracks.isEmpty) {
                      return const Center(
                        child: Text("No trending tracks found", style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return AlbumCard(
                          title: track.title,
                          subtitle: track.artist,
                          imageUrl: track.artworkUrl,
                          onTap: () => PlayerService().playTrackFromQueue(tracks, index),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 4. CAROUSEL 2: ELECTRONIC & DANCE TRENDS ("Featured Hits")
              _buildSectionHeader(
                "Featured Hits",
                onSeeAll: () => _openFullPlaylist("Featured Hits", _electronicTracksFuture),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: FutureBuilder<List<MusicTrack>>(
                  future: _electronicTracksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                    }
                    final tracks = snapshot.data ?? [];
                    if (tracks.isEmpty) {
                      return const Center(
                        child: Text("No tracks found", style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return AlbumCard(
                          title: track.title,
                          subtitle: track.artist,
                          imageUrl: track.artworkUrl,
                          onTap: () => PlayerService().playTrackFromQueue(tracks, index),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 130), // Padding so MiniPlayer does not cover the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessTile(String title, dynamic iconData, {bool isSvg = false, bool isGreen = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          isSvg
              ? SvgPicture.asset(iconData,
                  width: 24,
                  colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn))
              : Icon(
                  iconData as IconData,
                  color: isGreen ? AppColors.primaryGreen : AppColors.textPrimary,
                  size: 26,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onSeeAll,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              "See All",
              style: TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
