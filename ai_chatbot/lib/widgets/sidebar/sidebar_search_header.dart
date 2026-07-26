import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

// --- THE SEARCH HEADER ---
class SidebarSearchHeader extends StatelessWidget {
  final Function(String) onSearch;
  final VoidCallback onClose;

  const SidebarSearchHeader({super.key, required this.onSearch, required this.onClose});

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
          GestureDetector(onTap: onClose, child: Image.asset('lib/assets/drawer-icon.png', width: 40)),
        ],
      ),
    );
  }
}
