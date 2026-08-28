import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../widgets/album_card.dart';

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
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
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

              // 2. Quick Access Section (2x3 Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
                 children: [
                  _buildQuickAccessTile("Chill Vibes", Icons.playlist_play),
                  _buildQuickAccessTile("Coding Flow", Icons.playlist_play),
                  _buildQuickAccessTile("Gym Mix", Icons.playlist_play),
                  _buildQuickAccessTile("Liked Songs", Icons.favorite, isGreen: true),
                  _buildQuickAccessTile("Discover Weekly", Icons.auto_awesome),
                  _buildQuickAccessTile("Recently Played", Icons.history),
                ],
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
    IconData icon, {
    bool isGreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
          ),
          Icon(
            icon,
            color: isGreen ? AppColors.primaryGreen : AppColors.textPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
