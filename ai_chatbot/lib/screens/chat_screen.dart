import 'package:flutter/material.dart';
import '../backend/chat_screen/chat_screen_logic.dart';
import '../database/auth_services.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import 'sidebar.dart';
import 'login_screen.dart';
import 'nexa_interface.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatScreenLogic logic = ChatScreenLogic();
  late DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    dbService = DatabaseService(uid: AuthService.instance.currentUserId);
    logic.refreshSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF161717)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text("NEXA"),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Image.asset('lib/assets/drawer-icon.png', width: 35),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
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
        body: const Center(
          child: Text(
            "NEXA DASHBOARD",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
}
