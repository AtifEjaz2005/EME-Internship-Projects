import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_chatbot/backend/sidebar/sidebar_logic.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import 'package:ai_chatbot/widgets/sidebar/sidebar_user_logout_section.dart';
import 'package:ai_chatbot/widgets/sidebar/sidebar_search_header.dart';
import 'package:ai_chatbot/screens/profile_edit_screen.dart';

class Sidebar extends StatefulWidget {
  final DatabaseService dbService;
  final Function(String) onChatSelected;
  final VoidCallback onNewChat;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.dbService,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onLogout,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final SidebarLogic logic = SidebarLogic();
  final String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? "User Email";

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP: Search and Logo
          SidebarSearchHeader(
            onSearch: (val) => setState(() => logic.searchQuery = val),
            onProfileTap: () {
              // 1. Close the sidebar drawer first
              Navigator.pop(context);
              // 2. Open the Edit Profile screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ProfileEditScreen()),
              );
            },
          ),

          const Divider(color: Colors.white24),

          // 2. New Chat Button
          ListTile(
            leading: const Icon(Icons.add, color: AppTheme.limeGreen),
            title: const Text(
              "New Chat",
              style: TextStyle(color: Colors.white),
            ),
            onTap: widget.onNewChat,
          ),

          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, bottom: 5),
            child: Text(
              "Recents",
              style: TextStyle(
                color: AppTheme.limeGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // 3. MIDDLE: Scrollable Chat List
          Expanded(child: _buildChatList()),

          // 4. BOTTOM: Email and Logout
          SidebarUserSection(email: userEmail, onLogout: widget.onLogout),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder(
      stream: widget.dbService.getChatSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        // Filter chats using the Logic class
        var filteredChats = logic.filterChats(snapshot.data!.docs);

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            var chatDoc = filteredChats[index];
            Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;

            return ListTile(
              dense: true,
              title: Text(
                data.containsKey('title')
                    ? data['title']
                    : "Chat ${chatDoc.id.substring(0, 5)}",
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => widget.onChatSelected(chatDoc.id),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: () => _confirmDelete(chatDoc.id),
              ),
            );
          },
        );
      },
    );
  }

  // Simple delete confirmation popup
  void _confirmDelete(String chatId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: const Text("Delete?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) widget.dbService.deleteChat(chatId);
  }
}
