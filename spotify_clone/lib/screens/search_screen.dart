import 'package:flutter/material.dart';
import 'dart:async';
import '../themes/app_colors.dart';
import '../widgets/category_card.dart';
import '../services/player_service.dart';
import '../services/audius_provider.dart';
import '../models/music_track.dart';
import '../services/playlist_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // If the user is still typing, cancel the previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Wait 400ms after the user stops typing before searching
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

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
                onChanged: _onSearchChanged,
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
                    ? _buildBrowseAll()
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BROWSE ALL UI (Kept from your previous design) ---
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

  // --- AUDIUS INTEGRATION: Search Results ---
  Widget _buildSearchResults() {
    return FutureBuilder<List<MusicTrack>>(
      // Uses the official Audius Search API
      future: AudiusProvider().search(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error searching Audius",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(
            child: Text(
              "No songs found on Audius",
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final track = results[index];
            return ListTile(
              onTap: () {
                // Calls the updated playTrack method in PlayerService
                PlayerService().playTrack(track);
                FocusScope.of(context).unfocus(); // Close keyboard
              },
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: track.artworkUrl.isNotEmpty
                    ? Image.network(
                        track.artworkUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${track.artist} • Audius",
                style: const TextStyle(color: AppColors.textMuted),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onPressed: () => _showAddToPlaylistBottomSheet(context, track),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddToPlaylistBottomSheet(BuildContext context, MusicTrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: track.artworkUrl.isNotEmpty
                            ? Image.network(
                                track.artworkUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.white10,
                                ),
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                color: Colors.white10,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    "Add to Playlist",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                // List of user's playlists from Firestore
                Flexible(
                  child: StreamBuilder<List<PlaylistModel>>(
                    stream: PlaylistService().getUserPlaylists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      final playlists = snapshot.data ?? [];

                      if (playlists.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No custom playlists found. Create one first!",
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.playlist_add,
                              color: AppColors.primaryGreen,
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () async {
                              await PlaylistService().addSongToPlaylist(
                                playlistId: playlist.id,
                                track: track,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.surfaceHigh,
                                    content: Text(
                                      "Added to ${playlist.name}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceHigh,
      child: const Icon(Icons.music_note, color: Colors.white24),
    );
  }
}
