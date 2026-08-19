import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import '../models/message.dart';
import '../widgets/chat_screen/chat_bubble.dart';
import 'package:ai_chatbot/widgets/chat_screen/add_user_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_chatbot/screens/voice_call_screen.dart';
import 'package:ai_chatbot/screens/video_call_screen.dart';

class PeerChatInterface extends StatefulWidget {
  final String roomId;
  final String friendName;
  final DatabaseService dbService;

  const PeerChatInterface({
    super.key,
    required this.roomId,
    required this.friendName,
    required this.dbService,
  });

  @override
  State<PeerChatInterface> createState() => _PeerChatInterfaceState();
}

class _PeerChatInterfaceState extends State<PeerChatInterface> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Clear unread messages for me when I open the room
    widget.dbService.resetUnreadCount(widget.roomId);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // void _startCall({required bool isVideo}) {
  //   // Get the friend's ID from the Room ID (RoomID is "MyID_FriendID")
  //   // String friendId = widget.roomId
  //   //     .split('_')
  //   //     .firstWhere((id) => id != widget.dbService.uid);

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => CallScreen(
  //         roomId: widget.roomId,
  //         isCaller: true,
  //         dbService: widget.dbService,
  //         // We will update CallScreen to handle isVideo in the next step
  //       ),
  //     ),
  //   );
  // }

  void _handleCallInitiation({required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isVideo
            ? VideoCallScreen(
                roomId: widget.roomId,
                isCaller: true,
                dbService: widget.dbService,
              )
            : VoiceCallScreen(
                roomId: widget.roomId,
                isCaller: true,
                friendName: widget.friendName,
                dbService: widget.dbService,
              ),
      ),
    );
  }

  void _sendHumanMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    // Get the friend's ID from the Room ID (since it's ID1_ID2)
    String friendId = widget.roomId
        .split('_')
        .firstWhere((id) => id != widget.dbService.uid);

    // Save message to the shared 'rooms' collection
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': widget.dbService.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Update the 'Last Message' for the dashboard preview
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({
          'lastMessage': text, // Now shows the actual message
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unread_$friendId': FieldValue.increment(1),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.friendName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Move name to left to make room for icons
        // --- ADDED CALLING BUTTONS ---
        actions: [
          // VOICE CALL BUTTON
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppTheme.limeGreen),
            onPressed: () =>
                _handleCallInitiation(isVideo: false), // Now it finds it!
          ),
          // VIDEO CALL
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppTheme.limeGreen),
            onPressed: () =>
                _handleCallInitiation(isVideo: true), // Now it finds it!
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // --- 2. THE "ADD TO CONTACT" BANNER ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              var roomData = snapshot.data!.data() as Map<String, dynamic>;

              // GET FRESH UID inside the builder
              String myId = FirebaseAuth.instance.currentUser?.uid ?? "";

              // Check if YOU have saved a name for the person in this room
              if (roomData['name_$myId'] == null) {
                return Container(
                  width: double.infinity,
                  color: AppTheme.limeGreen.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "This user is not in your contacts",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddUserDialog(
                              dbService: widget.dbService,
                              // Use the phone number from the room data
                              lockedPhone: roomData['phone_$myId'],
                              onUserAdded: (roomId, name) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("$name saved to contacts"),
                                    backgroundColor: AppTheme.limeGreen,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: const Text(
                          "Add to Contact",
                          style: TextStyle(
                            color: AppTheme.limeGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.dbService.uid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChatBubble(
                        message: Message(text: data['text'], isUser: isMe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildSimpleInput(),
        ],
      ),
    );
  }

  Widget _buildSimpleInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 25, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Message",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendHumanMessage,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppTheme.limeGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
