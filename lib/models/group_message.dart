import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? ciphertext;
  final String? nonce;
  final String? mac;
  final Map<String, dynamic>? encryptedKeys;
  final Timestamp timestamp;
  final String? senderImageUrl;

  GroupMessage({
    this.id = '',
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.ciphertext,
    this.nonce,
    this.mac,
    this.encryptedKeys,
    required this.timestamp,
    this.senderImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'ciphertext': ciphertext,
      'nonce': nonce,
      'mac': mac,
      'encryptedKeys': encryptedKeys,
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
      ciphertext: map['ciphertext'] ?? '',
      nonce: map['nonce'] ?? '',
      mac: map['mac'] ?? '',
      encryptedKeys: Map<String, dynamic>.from(map['encryptedKeys'] ?? {}),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      senderImageUrl: map['senderImageUrl'],
    );
  }
}
