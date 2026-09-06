// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../widgets/category_card.dart';
import '../services/player_service.dart';
import '../services/youtube_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Search",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // 1. PILL SEARCH BAR (Design Spec #13)
              TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "What do you want to listen to?",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. DYNAMIC CONTENT AREA
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildBrowseAll() // Show Categories if search is empty
                    : _buildSearchResults(), // Show Songs if user is typing
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI for "Browse All" Categories
  Widget _buildBrowseAll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Browse all",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: const [
              CategoryCard(title: "Podcasts", color: Color(0xFFE8115B)),
              CategoryCard(title: "Made For You", color: Color(0xFF1E3264)),
              CategoryCard(title: "Charts", color: Color(0xFF8D67AB)),
              CategoryCard(title: "New Releases", color: Color(0xFF7358FF)),
              CategoryCard(title: "Pop", color: Color(0xFF148A08)),
              CategoryCard(title: "Hip-Hop", color: Color(0xFFBC5900)),
            ],
          ),
        ),
      ],
    );
  }

  // Backend Integration: Firestore Search
  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // This triggers the search every time the user types
      future: YouTubeService().searchSongs(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No results found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final results = snapshot.data!;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final song = results[index];
            return ListTile(
              onTap: () {
                // Call the new YouTube-specific play method
                PlayerService().playYoutubeSong(
                  song['id'], // The YouTube Video ID
                  song['title'], // The Title
                  song['artist'], // The Channel Name
                  song['imageUrl'], // The Thumbnail
                );

                // Close keyboard for better UX
                FocusScope.of(context).unfocus();
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  song['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                song['title'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                song['artist'],
                style: const TextStyle(color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
