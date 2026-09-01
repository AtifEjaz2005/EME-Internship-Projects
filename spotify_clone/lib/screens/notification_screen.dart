import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: AppColors.primaryGreen),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("New Release", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Text("Neon Voyager just dropped a new single!", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      Text("${index + 1}h ago", style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
