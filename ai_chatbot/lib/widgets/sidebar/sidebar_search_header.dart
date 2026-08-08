import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

// --- THE SEARCH HEADER ---
class SidebarSearchHeader extends StatelessWidget {
  final Function(String) onSearch;
  final VoidCallback onProfileTap; // Changed from onClose

  const SidebarSearchHeader({super.key, required this.onSearch, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 15, right: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                onChanged: onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search chats...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  isCollapsed: true,
                  prefixIcon: Icon(Icons.search, color: AppTheme.limeGreen, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // --- CHANGED: NEXA icon to Profile Icon ---
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.limeGreen, width: 1.5),
              ),
              child: const Icon(Icons.person, color: AppTheme.limeGreen, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
