import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import '../models/message.dart';
import '../widgets/chat_screen/chat_bubble.dart';

class PeerChatInterface extends StatefulWidget {
  final String roomId;
  final String friendName;
  final DatabaseService dbService;

  const PeerChatInterface({super.key, required this.roomId, required this.friendName, required this.dbService});

  @override
  State<PeerChatInterface> createState() => _PeerChatInterfaceState();
}

class _PeerChatInterfaceState extends State<PeerChatInterface> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendHumanMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

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
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        elevation: 0,
        title: Text(widget.friendName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
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
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    // Check: Did I send this or did the friend?
                    bool isMe = data['senderId'] == widget.dbService.uid;

                    return ChatBubble(
                      message: Message(text: data['text'], isUser: isMe),
                    );
                  },
                );
              },
            ),
          ),
          // Simple Input Area (No Mic for now, just Text)
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
              decoration: BoxDecoration(color: const Color(0xFF242526), borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "Message", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendHumanMessage,
            child: Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(color: AppTheme.limeGreen, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
