import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String message;
  final Timestamp timestamp;
  final String? senderImageUrl;
  
  GroupMessage({
    this.id = '',
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.senderImageUrl,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'senderImageUrl': senderImageUrl,
    };
  }
  
  factory GroupMessage.fromMap(Map<String, dynamic> map, String id) {
    return GroupMessage(
      id: id,
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      senderImageUrl: map['senderImageUrl'],
    );
  }
}