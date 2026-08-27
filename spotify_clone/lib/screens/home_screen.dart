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
                  const Text("Veyra",
                    style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary)),
                      const CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceHigh, child: Icon(Icons.person, size: 20, color: Colors.white)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              Text(_getGreeting(), style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),

              const SizedBox(height: 24),

              // 2. Quick Access Section (2x3 Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
                children: [
                  _buildQuickAccessTile("Discover Weekly", Icons.auto_awesome),
                  _buildQuickAccessTile("Release Radar", Icons.e_mobiledata),
                  _buildQuickAccessTile("Daily Mix 1", Icons.favorite),
                  _buildQuickAccessTile("Liked Songs", Icons.favorite_border),
                  _buildQuickAccessTile("On Repeat", Icons.repeat),
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
                    AlbumCard(title: "Chill Electronic", subtitle: "Your weekly mixtape of discoveries", imageUrl: "https://via.placeholder.com/160"),
                    AlbumCard(title: "Synthwave Classics", subtitle: "Retro-futuristic beats", imageUrl: "https://via.placeholder.com/160"),
                    AlbumCard(title: "Night Drive Vibes", subtitle: "Perfect for late night roads", imageUrl: "https://via.placeholder.com/160"),
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
                    AlbumCard(title: "Analog Dreams", subtitle: "Neon Voyager", imageUrl: "https://via.placeholder.com/160"),
                    AlbumCard(title: "Neon Horizon", subtitle: "Synthwave Syndicate", imageUrl: "https://via.placeholder.com/160"),
                    AlbumCard(title: "Desert Synth", subtitle: "Neon Voyager", imageUrl: "https://via.placeholder.com/160"),
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

  Widget _buildQuickAccessTile(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
            ),
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("See All", style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
