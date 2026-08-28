import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bgColor;
  final double size;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 160,
              height: 160,
              color: bgColor, // Use the distinct color here
              child: const Center(
                child: Icon(Icons.music_note, color: Colors.white, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
