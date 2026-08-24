import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../widgets/mini_player.dart';
import '../services/auth_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // These are your 3 pages
  final List<Widget> _pages = [
    const Center(child: Text("Home", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Search", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Library", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // 1. THIS IS THE BODY (Where the Logout button is)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pages[_currentIndex], // Shows Home, Search, or Library text
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => AuthService().signOut(),
                  child: const Text("LOGOUT"),
                ),
              ],
            ),
          ),

          // 2. MINI PLAYER
          const Positioned(
            left: 0, right: 0, bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),

      // 3. NAVIGATION BAR (Exactly 3 items)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surfaceLow,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
        ],
      ),
    );
  }
}
