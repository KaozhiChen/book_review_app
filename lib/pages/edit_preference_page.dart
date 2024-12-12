import 'package:book_review_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPreferencePage extends StatelessWidget {
  final List<String> currentPreferences;

  const EditPreferencePage({
    super.key,
    required this.currentPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return _EditPreferencesContent(
      currentPreferences: currentPreferences,
    );
  }
}

class _EditPreferencesContent extends StatefulWidget {
  final List<String> currentPreferences;

  const _EditPreferencesContent({
    required this.currentPreferences,
  });

  @override
  State<_EditPreferencesContent> createState() =>
      _EditPreferencesContentState();
}

class _EditPreferencesContentState extends State<_EditPreferencesContent> {
  final List<String> allGenres = [
    'Fiction',
    'Fantasy',
    'Science Fiction',
    'Mystery',
    'Romance',
    'Horror',
    'Biography',
    'History',
    'Poetry',
    'Adventure',
    'Children',
    'Travel',
    'Cooking',
    'Religion',
    'Art',
    'Health',
    'Business',
    'Technology',
    'Education',
    'Drama',
    'Philosophy',
    'Science',
    'Sports',
    'Politics',
    'Economics',
  ];
  late List<String> selectedPreferences;

  @override
  void initState() {
    super.initState();
    selectedPreferences = List.from(widget.currentPreferences);
  }

  Future<void> _savePreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'preferences': selectedPreferences});

      Navigator.of(context).pop(selectedPreferences);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save preferences: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Preferences",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: allGenres.map((genre) {
              final isSelected = selectedPreferences.contains(genre);
              return FilterChip(
                label: Text(genre),
                selected: isSelected,
                selectedColor: primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedPreferences.add(genre);
                    } else {
                      selectedPreferences.remove(genre);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: secondaryColor),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
