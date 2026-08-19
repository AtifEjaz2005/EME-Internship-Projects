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

  Future<void> updateCallStatus(String roomId, String status) async {
    await _db.collection('calls').doc(roomId).update({'status': status});
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

  // 1.3: THE STABLE ROOM CREATOR
  Future<String> getOrCreateChatRoom(
    String friendUid,
    String friendNickname,
    String friendPhone,
  ) async {
    // Ensure we have a clean UID
    String myId = uid.trim();
    String fId = friendUid.trim();

    // Create the unique Room Address
    List<String> ids = [myId, fId];
    ids.sort();
    String roomId = ids.join("_");

    // Get your own phone number so the friend knows who you are
    var myDoc = await _db.collection('users').doc(myId).get();
    String myPhone = myDoc.data()?['phone'] ?? "Unknown";

    await _db.collection('rooms').doc(roomId).set(
      {
        'roomId': roomId,
        'members': [myId, fId],
        'lastMessageTime': FieldValue.serverTimestamp(),

        // SAVE NICKNAME: specifically for YOU (myId)
        'name_$myId': friendNickname,
        'phone_$myId': friendPhone,

        // For the friend, we leave their nickname for you as null (Unknown)
        // but we provide them your phone number
        'phone_$fId': myPhone,
      },
      SetOptions(merge: true),
    ); // MERGE is critical so we don't delete old data

    return roomId;
  }

  // 1. Reset unread count when opening a chat
  Future<void> resetUnreadCount(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'unread_$uid': 0, // Set my unread count to 0
    });
  }

  // --- MODULE 1: WebRTC SIGNALING TOOLS ---

  // 1. CREATE A CALL: This starts the signaling process
  Future<void> createCallDocument(
    String roomId,
    Map<String, dynamic> offer,
    String receiverId,
    bool isVideo,
    String callerName,
  ) async {
    await _db.collection('calls').doc(roomId).set({
      'callerId': uid,
      'receiverId': receiverId,
      'callerName': callerName,
      'offer': offer,
      'isVideo': isVideo,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. ANSWER A CALL: This allows User B to accept the invitation
  Future<void> answerCall(String roomId, Map<String, dynamic> answer) async {
    await _db.collection('calls').doc(roomId).update({
      'answer': answer, // The "Technical Acceptance"
      'status': 'connected',
    });
  }

  // 3. CLEANUP: Delete the signaling data when the call ends
  Future<void> endCall(String roomId) async {
    // Delete the candidates sub-collections first
    var callerCandidates = await _db
        .collection('calls')
        .doc(roomId)
        .collection('callerCandidates')
        .get();
    for (var doc in callerCandidates.docs) {
      await doc.reference.delete();
    }

    var receiverCandidates = await _db
        .collection('calls')
        .doc(roomId)
        .collection('receiverCandidates')
        .get();
    for (var doc in receiverCandidates.docs) {
      await doc.reference.delete();
    }

    // Finally delete the main call document
    await _db.collection('calls').doc(roomId).delete();
  }

  Future<void> prepareCall(String roomId) async {
    final callRef = _db.collection('calls').doc(roomId);

    final callerCandidates = await callRef.collection('callerCandidates').get();

    for (final doc in callerCandidates.docs) {
      await doc.reference.delete();
    }

    final receiverCandidates = await callRef
        .collection('receiverCandidates')
        .get();

    for (final doc in receiverCandidates.docs) {
      await doc.reference.delete();
    }

    await callRef.delete();
  }

  // 4. ADD AN ICE CANDIDATE: Saves your "Digital Address" to the shared locker
  Future<void> addIceCandidate(
    String roomId,
    Map<String, dynamic> candidate,
    bool isCaller,
  ) async {
    // If I am the caller, I save to 'callerCandidates'
    // If I am the receiver, I save to 'receiverCandidates'
    String subCollection = isCaller ? 'callerCandidates' : 'receiverCandidates';

    await _db
        .collection('calls')
        .doc(roomId)
        .collection(subCollection)
        .add(candidate);
  }

  // 5. LISTEN FOR ICE CANDIDATES: A live stream to hear the other person's address
  Stream<QuerySnapshot<Map<String, dynamic>>> getIceCandidates(
    String roomId,
    bool listenForCaller,
  ) {
    String subCollection = listenForCaller
        ? 'callerCandidates'
        : 'receiverCandidates';

    return _db
        .collection('calls')
        .doc(roomId)
        .collection(subCollection)
        .snapshots();
  }
}
