import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final List<String> members;
  final List<String> admins;
  final Timestamp createdAt;
  final Timestamp? lastMessageTime;
  final String? lastMessage;
  final String? lastMessageSender;
  
  Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdBy,
    required this.members,
    required this.admins,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessage,
    this.lastMessageSender,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'members': members,
      'admins': admins,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
    };
  }
  
  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      createdBy: map['createdBy'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastMessageTime: map['lastMessageTime'],
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
    );
  }
  
  // Return true if the given user is an admin of this group
  bool isUserAdmin(String userId) {
    return admins.contains(userId);
  }
  
  // Get number of members excluding the current user
  int get memberCount => members.length;
}