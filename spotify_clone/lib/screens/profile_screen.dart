import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../themes/app_colors.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: const Center(child: Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().getCurrentUserData(),
        builder: (context, snapshot) {
          String name = snapshot.data?['name'] ?? "User";

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceHigh,
                  child: Icon(Icons.person, size: 50, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(user?.email ?? "", style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 40),

                _buildProfileItem(Icons.notifications_none, "Notifications", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }),
                _buildProfileItem(Icons.face_unlock_outlined, "Face ID & Passcode", () {}),
                _buildProfileItem(Icons.help_outline, "Support", () {}),
                _buildProfileItem(Icons.gavel_outlined, "Legal", () {}),
                _buildProfileItem(Icons.lock_open_outlined, "Permissions", () {}),

                const SizedBox(height: 40),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    Navigator.pop(context);
                  },
                  child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
    );
  }
}
