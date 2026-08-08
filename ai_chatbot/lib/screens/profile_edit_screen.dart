import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../themes/app_theme.dart';
import '../database/database_service.dart';
import '../database/auth_services.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // Pre-fill the boxes with existing data
  void _loadCurrentData() async {
    var uid = AuthService.instance.currentUserId;
    var snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = snap.data() as Map<String, dynamic>;

    fNameController.text = data['firstName'] ?? "";
    lNameController.text = data['lastName'] ?? "";
    phoneController.text = data['phone'] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: AppTheme.gradientBg,
        child: Center(
          child: _buildGlassCard(),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return Container(
      width: 400, padding: const EdgeInsets.all(30), margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          _buildInput(fNameController, "First Name", Icons.person),
          _buildInput(lNameController, "Last Name", Icons.person_outline),
          _buildInput(phoneController, "Phone Number", Icons.phone),
          const SizedBox(height: 30),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.limeGreen),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: AppTheme.limeGreen),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _saveData,
          child: const Text("Apply", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _saveData() async {
    setState(() => isLoading = true);
    await DatabaseService(uid: AuthService.instance.currentUserId)
        .updateProfile(fNameController.text, lNameController.text, phoneController.text);
    if (mounted) Navigator.pop(context);
  }
}
