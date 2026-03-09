import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firebase_constants.dart';

class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.username,
    required this.usernameLower,
    required this.passwordHash,
    required this.createdAt,
    this.profilePic = '',
    this.isOnline = false,
    this.lastSeen,
  });

  final String userId;
  final String name;
  final String username;
  final String usernameLower;
  final String passwordHash;
  final DateTime createdAt;
  final String profilePic;
  final bool isOnline;
  final DateTime? lastSeen;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirebaseFields.userId: userId,
      FirebaseFields.name: name,
      FirebaseFields.username: username,
      FirebaseFields.usernameLower: usernameLower,
      FirebaseFields.passwordHash: passwordHash,
      FirebaseFields.profilePic: profilePic,
      FirebaseFields.createdAt: Timestamp.fromDate(createdAt),
      FirebaseFields.isOnline: isOnline,
      FirebaseFields.lastSeen: lastSeen == null
          ? null
          : Timestamp.fromDate(lastSeen!),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: _stringValue(map[FirebaseFields.userId]),
      name: _stringValue(map[FirebaseFields.name]),
      username: _stringValue(map[FirebaseFields.username]),
      usernameLower: _stringValue(map[FirebaseFields.usernameLower]),
      passwordHash: _stringValue(map[FirebaseFields.passwordHash]),
      profilePic: _stringValue(map[FirebaseFields.profilePic]),
      createdAt: _dateValue(map[FirebaseFields.createdAt]) ?? DateTime.now(),
      isOnline: _boolValue(map[FirebaseFields.isOnline]),
      lastSeen: _dateValue(map[FirebaseFields.lastSeen]),
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? username,
    String? usernameLower,
    String? passwordHash,
    DateTime? createdAt,
    String? profilePic,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      profilePic: profilePic ?? this.profilePic,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  static String _stringValue(dynamic value) {
    if (value is String) {
      return value;
    }
    return '';
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }
    return false;
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
