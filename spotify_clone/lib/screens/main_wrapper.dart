import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify_clone/screens/library_screen.dart';
import 'package:spotify_clone/screens/search_screen.dart';
import '../themes/app_colors.dart';
import '../widgets/mini_player.dart';
import 'package:spotify_clone/screens/home_screen.dart';
import 'package:spotify_clone/services/auth_service.dart';
import '../screens/playlist_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _isCreateOpen = false;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We keep background color, but body will contain our custom Nav Bar
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // 1. THE MAIN CONTENT (Home, Search, Library)
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex > 2 ? 0 : _currentIndex,
              children: _pages,
            ),
          ),

          // 2. THE BOTTOM GRADIENT (SCRIM) - Makes the Nav Bar beautiful
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 150, // Height of the gradient fade
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9), // High contrast at bottom
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,           // Fades to nothing
                ],
              ),
            ),
          ),
        ),

          // 2. DIM OVERLAY (Only when Create is open)
          if (_isCreateOpen)
            GestureDetector(
              onTap: () => setState(() => _isCreateOpen = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),

          // 3. THE POPUP MENU (Above the Nav Bar)
          if (_isCreateOpen)
            Positioned(
              bottom: 95, // Pushed up to clear the white X button
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDefault,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPopupItem(Icons.music_note, "Playlist", "Create a playlist", () {
                      setState(() => _isCreateOpen = false);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePlaylistScreen()));
                    }),
                    _buildPopupItem(Icons.people_outline, "Collaborative", "Create with friends", () {}),
                    _buildPopupItem(Icons.waves, "Blend", "Combine your tastes", () {}),
                  ],
                ),
              ),
            ),

          // 4. THE MINI PLAYER (Hidden when Create is Open)
          if (!_isCreateOpen)
            const Positioned(
              bottom: 80, // Pushed up slightly to stay above the Nav Bar
              left: 0,
              right: 0,
              child: MiniPlayer(),
            ),

          // 5. THE CUSTOM FLOATING NAV BAR (True Transparency)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              color: Colors.transparent, // Zero background
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _customNavItem(0, Icons.home_filled, "Home"),
                  _customNavItem(1, Icons.search, "Search"),
                  _customNavItem(2, null, "Library", svg: 'lib/assets/library.svg'),
                  _createToggleButton(), // THE TOGGLE BUTTON (Create vs X)
                  _customNavItem(4, Icons.logout, "Logout"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REUSABLE NAV ITEM (Home, Search, Library, Logout)
  Widget _customNavItem(int index, IconData? icon, String label, {String? svg}) {
    // CHANGE: Use White for selection
    bool isSelected = _currentIndex == index && !_isCreateOpen;
    Color activeColor = Colors.white; // Changed from Green to White
    Color inactiveColor = AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          _showLogoutDialog();
        } else {
          setState(() {
            _currentIndex = index;
            _isCreateOpen = false;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          svg != null
              ? SvgPicture.asset(
                  svg,
                  width: 30, // Increased from 26
                  colorFilter: ColorFilter.mode(
                      isSelected ? activeColor : inactiveColor,
                      BlendMode.srcIn),
                )
              : Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 30, // Increased from 28
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 10, // Increased from 10
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // THE TOGGLE BUTTON: Create (+) vs Close (X)
  Widget _createToggleButton() {
    return GestureDetector(
      onTap: () => setState(() => _isCreateOpen = !_isCreateOpen),
      child: _isCreateOpen
          ? Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white, // White circle
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 28), // Black X
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppColors.textMuted, size: 30),
                const SizedBox(height: 4),
                const Text(
                  "Create",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _buildPopupItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceHigh,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDefault,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.primaryGreen, size: 60),
              const SizedBox(height: 16),
              const Text("Logout", style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Are you sure you want to sign out?", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    if (mounted) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("LOGOUT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
