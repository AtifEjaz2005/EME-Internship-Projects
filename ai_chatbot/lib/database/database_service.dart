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

  Future<void> updateProfile(String fName, String lName, String phone) async {
    await _db.collection('users').doc(uid).update({
      'firstName': fName,
      'lastName': lName,
      'phone': phone,
    });
  }

  Future<String?> getLatestChatId() async {
    try {
      var snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      print("Error fetching last chat: $e");
    }
    return null;
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

  // This searches the WHOLE 'users' folder to find a match
  Future<Map<String, dynamic>?> findUserByPhone(String phoneNumber) async {
    try {
      // Look for anyone whose 'phone' field matches the input
      var result = await _db
          .collection('users')
          .where('phone', isEqualTo: phoneNumber.trim())
          .get();

      if (result.docs.isNotEmpty) {
        // SUCCESS: Found them! Return their Name and UID
        return result.docs.first.data();
      } else {
        // NOT FOUND: No one is registered with this number
        return null;
      }
    } catch (e) {
      print("Search Error: $e");
      return null;
    }
  }

  // This ensures both users look at the same folder
   Future<String> getOrCreateChatRoom(String friendUid, String friendNickname, String friendPhone) async {
    // A. Combine IDs to make the unique Room Address
    List<String> ids = [uid, friendUid];
    ids.sort();
    String roomId = ids.join("_");

    // B. Get YOUR info (so User B knows your number)
    var myDoc = await _db.collection('users').doc(uid).get();
    String myPhone = myDoc.get('phone') ?? "Unknown";

    DocumentReference roomRef = _db.collection('rooms').doc(roomId);

    await roomRef.set({
      'roomId': roomId,
      'members': [uid, friendUid],
      'lastMessage': 'New conversation started',
      'lastMessageTime': FieldValue.serverTimestamp(),

      // We store the data for BOTH perspectives
      // User A (You) sees the Nickname you typed
      'name_$uid': friendNickname,
      'phone_$uid': friendPhone,

      // User B (Friend) has no nickname saved for you yet, so we store your phone as their default view
      'name_$friendUid': null,
      'phone_$friendUid': myPhone,

    }, SetOptions(merge: true));

    return roomId;
  }

  // 1. Reset unread count when opening a chat
  Future<void> resetUnreadCount(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'unread_$uid': 0, // Set my unread count to 0
    });
  }

  // 2. Add this to your updateProfile or create a new one to save a friend's name later
  Future<void> saveContactName(String roomId, String name) async {
    await _db.collection('rooms').doc(roomId).update({
      'name_$uid': name, // Save the nickname for my perspective
    });
  }
}
