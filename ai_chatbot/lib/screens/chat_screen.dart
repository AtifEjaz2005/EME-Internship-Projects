import 'package:flutter/material.dart';
import '../backend/chat_screen/chat_screen_logic.dart';
import '../database/auth_services.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import 'sidebar.dart';
import 'login_screen.dart';
import 'nexa_interface.dart';
import 'package:ai_chatbot/widgets/chat_screen/add_user_form.dart';
import 'package:ai_chatbot/screens/peer_chat_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _activeFilter = "All"; // Logic for filters
  final ChatScreenLogic logic = ChatScreenLogic();
  late DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    dbService = DatabaseService(uid: AuthService.instance.currentUserId);
    logic.refreshSuggestions();

    logic.loadLastChat(dbService, () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF161717)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        drawer: Sidebar(
          dbService: dbService,
          onChatSelected: (id) {
            setState(() => logic.currentChatId = id);
            Navigator.pop(context);
            _openNexa();
          },
          onNewChat: () {
            setState(() => logic.currentChatId = null);
            Navigator.pop(context);
            _openNexa();
          },
          onLogout: () async {
            await AuthService.instance.signOut();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginScreen()),
                (r) => false,
              );
            }
          },
        ),
        body: Column(
          children: [
            // 2. FULL WIDTH SEARCH BAR
            _buildSearchBar(),

            // 3. FILTER CHIPS
            _buildFilters(),

            // 4. THE HUMAN CHAT LIST
            Expanded(child: _buildHumanChatList()),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 0, bottom: 0),
          child: SizedBox(
            width: 60,
            height: 60,
            child: FloatingActionButton(
              onPressed: _openNexa,
              backgroundColor: AppTheme.limeGreen,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset('lib/assets/drawer-icon.png', width: 45),
            ),
          ),
        ),
      ),
    );
  }

  void _openNexa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Ensure this matches the class name in NexaInterface
        builder: (context) => NexaInterface(logic: logic, dbService: dbService),
      ),
    ).then((_) => setState(() {})); // Refreshes dashboard when you return
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      centerTitle: true,

      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset('lib/assets/drawer-icon.png', width: 35),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),

      title: Image.asset(
        'lib/assets/nexa.png',
        height: 50, // Adjust this to fit your AppBar height
        fit: BoxFit.contain,
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: const Icon(
              Icons.person_add_rounded,
              color: AppTheme.limeGreen,
              size: 28,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddUserDialog(
                  dbService: dbService,
                  onUserAdded: (roomId, friendName) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Added $friendName to your contacts"),
                        backgroundColor: AppTheme.limeGreen,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search conversations...",
            hintStyle: TextStyle(color: Colors.white24),
            prefixIcon: Icon(Icons.search, color: Colors.white24),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    List<String> filters = ["All", "Unread"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isActive = _activeFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filters[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.limeGreen : const Color(0xFF242526),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHumanChatList() {
    return StreamBuilder<QuerySnapshot>(
      // 1. We remove 'orderBy' for a second to see if the data comes back.
      // If it works without orderBy, it proves you need to create an index!
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('members', arrayContains: dbService.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // 2. CHECK: If Firebase had an error, print it clearly
        if (snapshot.hasError) {
          print("DATABASE ERROR: ${snapshot.error}");
          return Center(
            child: Text(
              "Error loading chats",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // 3. Filter logic needs to be safe
        var docs = snapshot.data!.docs;

        // If docs are empty here, but you see them in Firebase Console,
        // it means 'dbService.uid' doesn't match the IDs in the 'members' list.
        var rooms = docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String myId = dbService.uid;
          String displayName = (data['name_$myId'] ?? data['phone_$myId'] ?? "")
              .toString()
              .toLowerCase();
          return displayName.contains(_searchQuery);
        }).toList();

        if (rooms.isEmpty) {
          return const Center(
            child: Text(
              "No contacts found",
              style: TextStyle(color: Colors.white24),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            var room = rooms[index].data() as Map<String, dynamic>;
            // GET FRESH UID: This is the most important change
            String myId = FirebaseAuth.instance.currentUser?.uid ?? "";

            // Check if a name exists for YOUR current UID
            String? savedName = room['name_$myId'];
            String phoneOfFriend = room['phone_$myId'] ?? "Unknown";
            // If name exists, use it. If not, show the number.
            String displayName = (savedName != null && savedName.isNotEmpty)
                ? savedName
                : phoneOfFriend;

            return ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => PeerChatInterface(
                    roomId: rooms[index].id,
                    friendName: displayName,
                    dbService: dbService,
                  ),
                ),
              ),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF4F5254),
                child: Icon(Icons.person, color: Colors.white54),
              ),
              title: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                room['lastMessage'] ?? "No messages yet",
                style: const TextStyle(color: Colors.white38),
                maxLines: 1,
              ),
              trailing: (room['unread_$myId'] ?? 0) > 0
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB6FF2E),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${room['unread_$myId']}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(),
            );
          },
        );
      },
    );
  }
}
