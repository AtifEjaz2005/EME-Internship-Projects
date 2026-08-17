import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPass;

  const LoginField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(color: AppTheme.darkBackground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.darkBackground),
          filled: true,
          fillColor: AppTheme.limeGreen,
          prefixIcon: Icon(icon, color: AppTheme.darkBackground),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
