import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../../themes/app_theme.dart';

class Step2Profile extends StatelessWidget {
  final Function(String) onAgeSelected;
  final Function(String) onCountrySelected;
  final String selectedAge;
  final String selectedCountry;

  const Step2Profile({super.key, required this.onAgeSelected, required this.onCountrySelected, required this.selectedAge, required this.selectedCountry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tell us about yourself", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        const Text("Select Age", style: TextStyle(color: Colors.white70)),
        DropdownButton<String>(
          dropdownColor: AppTheme.darkBackground, // Ensures menu is dark and readable
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.limeGreen),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          hint: const Text("Select your age", style: TextStyle(color: Colors.white38)),
          items: ["Under 18", "18-24", "25-34", "35-44", "45-54", "55+"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (v) => onAgeSelected(v!),
        ),
        const SizedBox(height: 30),
        const Text("Country", style: TextStyle(color: Colors.white70)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(selectedCountry.isEmpty ? "Pick your country" : selectedCountry, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.location_on, color: AppTheme.limeGreen),
          onTap: () => showCountryPicker(context: context, onSelect: (c) => onCountrySelected(c.name)),
        ),
      ],
    );
  }
}
