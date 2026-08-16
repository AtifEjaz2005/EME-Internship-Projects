import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../themes/app_theme.dart';

class AddUserDialog extends StatefulWidget {
  final DatabaseService dbService;
  final Function(String, String) onUserAdded; // To tell the screen who was added

  const AddUserDialog({super.key, required this.dbService, required this.onUserAdded});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Controller for Name
  bool _isLoading = false;
  String _errorMessage = "";

  void _handleSearch() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    // Ensure both fields are filled
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    // 1. Search for the user in the database
    var friendData = await widget.dbService.findUserByPhone(phone);

    if (friendData != null) {
      String friendUid = friendData['uid'];

      // 2. Create the shared Room using the CUSTOM NAME you entered in the form
      String roomId = await widget.dbService.getOrCreateChatRoom(friendUid, name);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // Close the popup
        widget.onUserAdded(roomId, name); // Open the chat
      }
    } else {
      // 3. Show error if phone number is not in system
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not found. This person is not registered on NEXA yet.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: const Text("Add Contact",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter the details of the person you want to add.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13)
          ),
          const SizedBox(height: 20),

          // --- NAME INPUT (NEW) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.limeGreen),
              decoration: const InputDecoration(
                hintText: "Contact Name",
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.limeGreen, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- PHONE INPUT ---
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.limeGreen),
              decoration: const InputDecoration(
                hintText: "Phone Number (e.g. +92...)",
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.phone, color: AppTheme.limeGreen, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          // Error Message Display
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.white54))
        ),
        _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: CircularProgressIndicator(color: AppTheme.limeGreen),
            )

          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleSearch,
              child: const Text("Add User", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
      ],
    );
  }
}
