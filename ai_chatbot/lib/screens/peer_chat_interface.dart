import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import '../models/message.dart';
import '../widgets/chat_screen/chat_bubble.dart';
import 'package:ai_chatbot/widgets/chat_screen/add_user_form.dart';
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
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unread_$friendId': FieldValue.increment(1),
        });
  }

  @override
  Widget build(BuildContext context) {
    String myId = widget.dbService.uid;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        elevation: 0,
        title: Text(
          widget.friendName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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

              // If we don't have a name saved for this user yet
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
                          // Open the REUSABLE FORM instead of the old dialog
                          showDialog(
                            context: context,
                            builder: (context) => AddUserDialog(
                              dbService: widget.dbService,
                              // PASS THE FRIEND'S PHONE NUMBER HERE
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
              return const SizedBox(); // Hide banner if name exists
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
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20),
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.dbService.uid;
                    return ChatBubble(
                      message: Message(text: data['text'], isUser: isMe),
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
