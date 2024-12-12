// import 'package:book_review_app/theme/colors.dart';
import 'package:book_review_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      // get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      // get user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userProfile = doc.data();
        });
      } else {
        throw Exception("User profile not found in Firestore.");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  void _showEditUsernameDialog() {
    final TextEditingController usernameController =
        TextEditingController(text: userProfile!['username']);

    // edit username
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Username"),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: "New Username",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  await _updateUsername(newUsername);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // update username
  Future<void> _updateUsername(String newUsername) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // update username to firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'username': newUsername});

      // update userProfile
      setState(() {
        userProfile!['username'] = newUsername;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username updated successfully!")),
      );
    } catch (e) {
      print("Error updating username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update username.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Section
            CircleAvatar(
              radius: 60,
              backgroundImage: userProfile!['avatarUrl'] != null
                  ? NetworkImage(userProfile!['avatarUrl'])
                  : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
              child: const Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera_alt, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Section
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text("Email",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userProfile!['email'] ?? "No Email"),
              ),
            ),
            const SizedBox(height: 8),

            // Username Section
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text("Username",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userProfile!['username'] ?? "No Username"),
                trailing: IconButton(
                    onPressed: () {
                      _showEditUsernameDialog();
                    },
                    icon: const Icon(Icons.edit)),
              ),
            ),

            // preference section
            const SizedBox(height: 8),
            const Divider(),
            const Text('Preferences:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 8,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (userProfile!['preferences'] as List<dynamic>)
                    .map((pref) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Chip(
                            label: Text(pref),
                            backgroundColor: primaryColor,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
