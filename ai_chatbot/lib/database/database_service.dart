import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'package:ai_chatbot/models/onboarding_model.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save message to a specific chat
  Future saveMessage(String chatId, Message msg) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': msg.text,
          'isUser': msg.isUser,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Create a new chat with a default title
  Future<String> createNewChat() async {
    DocumentReference doc = await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .add({
          'createdAt': FieldValue.serverTimestamp(),
          'title': 'New Chat', // Default title
        });
    return doc.id;
  }

  // Update the chat title after the first message
  Future<void> updateChatTitle(String chatId, String firstMessage) async {
    // We take the first 20 characters of the user's message as the title
    String title = firstMessage.length > 25
        ? "${firstMessage.substring(0, 22)}..."
        : firstMessage;

    await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(chatId)
        .update({'title': title});
  }

  // lib/database/database_service.dart

  Future<void> deleteChat(String chatId) async {
    try {
      // 1. Delete all messages inside the chat first
      var messages = await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the chat document itself
      await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  // Get all previous chat sessions for the sidebar
  Stream<QuerySnapshot> getChatSessions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get messages inside a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // Add this inside your DatabaseService class
  Future<List<QueryDocumentSnapshot>> getMessagesOnce(String chatId) async {
    var snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    return snapshot.docs;
  }

  Future<void> saveOnboarding(OnboardingModel data) async {
    try {
      await _db.collection('users').doc(uid).update(data.toMap());
    } catch (e) {
      print("Error saving onboarding data: $e");
    }
  }

  // Add this helper to get user data easily
  Future<Map<String, dynamic>> getUserData() async {
    var snap = await _db.collection('users').doc(uid).get();
    return snap.data() ?? {};
  }
}
