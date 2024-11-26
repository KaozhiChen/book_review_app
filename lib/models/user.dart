import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid; // User ID
  final String email; // User Email

  UserModel({
    required this.uid,
    required this.email,
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
    };
  }

  //  JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
    );
  }
}
