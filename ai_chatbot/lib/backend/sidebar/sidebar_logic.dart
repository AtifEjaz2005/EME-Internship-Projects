import 'package:cloud_firestore/cloud_firestore.dart';

class SidebarLogic {
  String searchQuery = "";

  // This function takes the big list of chats and returns only the ones that match your search
  List<QueryDocumentSnapshot> filterChats(List<QueryDocumentSnapshot> allChats) {
    return allChats.where((doc) {
      // 1. Get the title (or empty string if it doesn't exist)
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String title = data.containsKey('title') ? data['title'].toString().toLowerCase() : "";

      // 2. Also check the ID just in case
      String id = doc.id.toLowerCase();

      // 3. Return true if search matches title or ID
      return title.contains(searchQuery.toLowerCase()) || id.contains(searchQuery.toLowerCase());
    }).toList();
  }
}
