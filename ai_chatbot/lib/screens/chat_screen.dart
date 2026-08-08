import 'package:flutter/material.dart';
import 'package:ai_chatbot/backend/chat_screen/chat_screen_logic.dart';
import '../database/auth_services.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import 'package:ai_chatbot/widgets/chat_screen/chat_screen_suggested_ui.dart';
import 'package:ai_chatbot/widgets/chat_screen/chat_screen_input_area.dart';
import '../widgets/chat_screen/message_list.dart';
import 'sidebar.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatScreenLogic logic = ChatScreenLogic();
  late DatabaseService dbService;

  // to get the repective user chats and display random questions on the screen
  @override
  void initState() {
    super.initState();
    dbService = DatabaseService(uid: AuthService.instance.currentUserId);
    logic.refreshSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        drawer: _buildSidebar(),
        body: Column(
          children: [
            // THE MAIN VIEW AREA
            Expanded(
              child: logic.currentChatId == null
                  ? SuggestedUI(
                      suggestions: logic.currentSuggestions,
                      onTapSuggestion: (text) => logic.handleSendMessage(
                        text: text,
                        dbService: dbService,
                        updateUI: () => setState(() {}),
                      ),
                    )
                  : MessageList(
                      chatId: logic.currentChatId!,
                      dbService: dbService,
                      scrollController: logic.scrollController,
                      logic: logic,
                      currentlySpeakingText: logic.voice.currentlySpeakingText,
                      isTyping: logic.isTyping,
                      onNewMessage: () => logic.scrollToBottom(),
                      refreshIcon: () => setState(() {}),
                    ),
            ),

            // INPUT AREA
            ChatInputArea(
              controller: logic.messageController,
              isTyping: logic.isTyping,
              isListening: logic.voice.isListening,
              isPaused: logic.voice.isPaused,
              onMicTap: () => logic.toggleVoiceTyping(() => setState(() {})),
              onSend: () => logic.handleSendMessage(
                dbService: dbService,
                updateUI: () => setState(() {}),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  // widget for AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text("NEXA"),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset('lib/assets/drawer-icon.png', width: 45),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  // widget for Sidebar
  Widget _buildSidebar() {
    return Sidebar(
      dbService: dbService,
      onChatSelected: (id) => setState(() => logic.currentChatId = id),
      onNewChat: () => setState(() {
        logic.currentChatId = null;
        logic.refreshSuggestions();
      }),

      // this will logout the user and r => false will delete all the screens from stack so that user cannot login back without going to login page
      onLogout: () async {
        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }
}
