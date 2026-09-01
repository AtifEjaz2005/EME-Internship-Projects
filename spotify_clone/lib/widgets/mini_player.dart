import 'package:flutter/material.dart';
// import '../themes/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        // NEW COLOR: Deep charcoal translucent matching the reference
        color: const Color(0xFF141C21).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album Art
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              'https://via.placeholder.com/48',
              width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (context, e, s) => Container(
                color: Colors.white10,
                child: const Icon(Icons.music_note, color: Colors.white)
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Artist
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jhelum",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                ),
                Text(
                  "Faheem Abdullah",
                  style: TextStyle(color: Colors.white70, fontSize: 13)
                ),
              ],
            ),
          ),
          // Action Icons
          const Icon(Icons.devices_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          // THE NEW ADD (+) ICON
          const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
          const SizedBox(width: 16),
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
        ],
      ),
    );
  }
}
