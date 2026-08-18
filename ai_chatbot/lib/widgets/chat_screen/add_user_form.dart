import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../themes/app_theme.dart';

class AddUserDialog extends StatefulWidget {
  final DatabaseService dbService;
  final Function(String, String) onUserAdded;
  final String? lockedPhone; // Optional phone number for "Locked Mode"

  const AddUserDialog({
    super.key,
    required this.dbService,
    required this.onUserAdded,
    this.lockedPhone,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // If a phone number was passed (from a chat), put it in the box immediately
    if (widget.lockedPhone != null) {
      _phoneController.text = widget.lockedPhone!;
    }
  }

  void _handleSearch() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

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

      // 2. Create/Update shared Room (merge: true ensures messages are kept)
      String roomId = await widget.dbService.getOrCreateChatRoom(friendUid, name, phone);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onUserAdded(roomId, name);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not found. This user is not registered on NEXA.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the phone should be editable
    bool isReadOnly = widget.lockedPhone != null;

    return AlertDialog(
      backgroundColor: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Text(
        isReadOnly ? "Save Contact" : "Add Contact",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isReadOnly
              ? "Give this number a name to save it to your contacts."
              : "Enter the details of the person you want to add.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13)
          ),
          const SizedBox(height: 20),

          // --- NAME INPUT ---
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

          // --- PHONE INPUT (Disabled if isReadOnly is true) ---
          Container(
            decoration: BoxDecoration(
              // If read-only, make the background even darker/dimmer
              color: isReadOnly ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !isReadOnly, // LOCKS THE FIELD
              style: TextStyle(
                color: isReadOnly ? Colors.white38 : AppTheme.limeGreen,
              ),
              decoration: InputDecoration(
                hintText: "Phone Number",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(
                  Icons.phone,
                  color: isReadOnly ? Colors.white24 : AppTheme.limeGreen,
                  size: 20
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

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
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleSearch,
              child: Text(
                isReadOnly ? "Save" : "Add User",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
              ),
            ),
      ],
    );
  }
}
