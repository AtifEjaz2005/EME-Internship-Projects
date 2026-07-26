import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

// --- THE USER & LOGOUT SECTION ---
class SidebarUserSection extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;

  const SidebarUserSection({super.key, required this.email, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // User Email Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(height: 12),
        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GestureDetector(
            onTap: onLogout,
            child: Container(
              width: double.infinity, height: 48,
              decoration: BoxDecoration(color: AppTheme.limeGreen, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, color: AppTheme.darkBackground, size: 20),
                  SizedBox(width: 10),
                  Text("Logout", style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
