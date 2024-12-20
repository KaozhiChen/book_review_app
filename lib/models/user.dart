import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid; // User ID
  final String email; // User Email
  final String username; //username
  final List<String> preferences; // preference genres

  UserModel({
    required this.uid,
    required this.email,
    this.username = "",
    this.preferences = const [],
  });

  // Firebase User to UserModel
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email!,
    );
  }

  // convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'preferences': preferences,
    };
  }

  //  JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      preferences: List<String>.from(
          json['preferences'] ?? []), // Default to empty list if null
    );
  }
}
