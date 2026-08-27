import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../widgets/mini_player.dart';
import '../services/auth_service.dart';
import 'package:spotify_clone/screens/home_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // These are your 3 pages
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text("Search", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Library", style: TextStyle(color: Colors.white))),
  ];

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      // Use a Stack to layer the MiniPlayer OVER the pages
      body: Stack(
        children: [
          // IndexedStack preserves the state of your pages and handles sizing correctly
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // The MiniPlayer is fixed at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surfaceLow,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
        ],
      ),
    );
  }
}
