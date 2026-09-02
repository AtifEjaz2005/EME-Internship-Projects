import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/app_colors.dart';
import '../widgets/album_card.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';
import '../services/playlist_service.dart';
import '../screens/playlist_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Logo, Greeting, Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 55,
                    child: Image.asset(
                      'lib/assets/wordmark.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Row(
                    children: [
                      // Notification Icon with Green Dot
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              color: AppColors.textPrimary,
                              size: 30,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryBackground,
                                    width: 2,
                                  ),
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
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.account_circle_rounded,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 24),

              StreamBuilder<List<String>>(
                stream: PlaylistService().getPlaylists(),
                builder: (context, snapshot) {
                  // 1. Get user playlists or empty list
                  List<String> userPlaylists = snapshot.data ?? [];

                  // 2. Limit to top 4 and add the 2 "Must" tiles
                  List<String> displayList = userPlaylists.take(4).toList();
                  displayList.add("Other Playlists");
                  displayList.add("Liked Songs");

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, index) {
                      String name = displayList[index];
                      bool isUserPlaylist = index < (displayList.length - 2);
                      bool isLiked = name == "Liked Songs";

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistName: name,
                                isLikedSongs: isLiked,
                              ),
                            ),
                          );
                        },
                        child: _buildQuickAccessTile(
                          name,
                          isUserPlaylist ? 'lib/assets/library.svg' :
                          (isLiked ? Icons.favorite : Icons.playlist_play),
                          isSvg: isUserPlaylist,
                          isGreen: isLiked,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // 3. Made For You Carousel
              _buildSectionHeader("Made For You"),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    AlbumCard(
                      title: "Chill Electronic",
                      subtitle: "Your weekly mixtape",
                      bgColor: Color(0xFF2E3B4E),
                    ),
                    AlbumCard(
                      title: "Synthwave Classics",
                      subtitle: "Retro-futuristic",
                      bgColor: Color(0xFF4E2E3B),
                    ),
                    AlbumCard(
                      title: "Night Drive",
                      subtitle: "For the road",
                      bgColor: Color(0xFF2E4E3B),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Recently Played Carousel
              _buildSectionHeader("Recently Played"),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    AlbumCard(
                      title: "Analog Dreams",
                      subtitle: "Neon Voyager",
                      bgColor: Color(0xFF3F2E4E),
                    ),
                    AlbumCard(
                      title: "Neon Horizon",
                      subtitle: "Synthwave Syndicate",
                      bgColor: Color(0xFF4E462E),
                    ),
                    AlbumCard(
                      title: "Desert Synth",
                      subtitle: "Neon Voyager",
                      bgColor: Color(0xFF4E462E),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Space for MiniPlayer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessTile(
    String title,
    dynamic iconData, {
    bool isSvg = false,
    bool isGreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          isSvg
              ? SvgPicture.asset(
                  iconData,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  iconData == 'favorite' ? Icons.favorite : Icons.playlist_play,
                  color: isGreen
                      ? AppColors.primaryGreen
                      : AppColors.textPrimary,
                  size: 24,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "See All",
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
