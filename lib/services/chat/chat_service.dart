import 'package:chatty/services/crypto/encryption_service.dart';
import 'package:chatty/services/crypto/key_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  // create an instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get current user
  User? get currentUser => _auth.currentUser;

  // get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    try {
      return _firestore.collection("Users").snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          // check each user individually
          final user = doc.data();
          // return user
          return user;
        }).toList();
      });
    } catch (e) {
      print("Error getting user stream: $e");
      return Stream.value([]);
    }
  }

  // Get users that the current user has chatted with
  // Update the getChatUsers method to include usernames
  Stream<List<ChatUser>> getChatUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection("chat_rooms")
        .where('participants', arrayContains: currentUser.email)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChatUser> chatUsers = [];

          for (var doc in snapshot.docs) {
            String chatRoomId = doc.id;
            List<String> emails = chatRoomId.split('_');

            if (emails.length == 2) {
              // Determine which email belongs to the other user
              final otherUserEmail =
                  emails[0] == currentUser.email ? emails[1] : emails[0];

              // Get the other user's details from Users collection
              final userQuery =
                  await _firestore
                      .collection('Users')
                      .where('email', isEqualTo: otherUserEmail)
                      .limit(1)
                      .get();

              String username =
                  otherUserEmail; // Default to email if username not found
              String? profileImageUrl;

              if (userQuery.docs.isNotEmpty) {
                final userData = userQuery.docs.first.data();
                username = userData['username'] ?? otherUserEmail;
                profileImageUrl = userData['profileImageUrl'];
              }

              // Get the latest message for this chat
              final messagesSnapshot =
                  await _firestore
                      .collection("chat_rooms")
                      .doc(chatRoomId)
                      .collection("messages")
                      .orderBy("timestamp", descending: true)
                      .limit(1)
                      .get();

              String lastMessage = "";
              Timestamp? timestamp;

              if (messagesSnapshot.docs.isNotEmpty) {
                var messageData = messagesSnapshot.docs.first.data();
                lastMessage = messageData['decryptedPreview'] ?? "";
                timestamp = messageData['timestamp'] as Timestamp?;
              }

              chatUsers.add(
                ChatUser(
                  senderEmail: emails[0],
                  receiverEmail: emails[1],
                  lastMessage: lastMessage,
                  timestamp: timestamp ?? Timestamp.now(),
                  username: username,
                  profileImageUrl: profileImageUrl,
                ),
              );
            }
          }

          // Sort by most recent message
          chatUsers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return chatUsers;
        });
  }

  // SEND MESSAGE
  Future<String> sendMessage(String receiverEmail, String message) async {
    // get current user info
    final String currentUserEmail = currentUser!.email!;
    final String currentUserId = currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // Get receiver's UID
    String? receiverId = await _getUidFromEmail(receiverEmail);
    if (receiverId == null) {
      throw Exception('Receiver not found');
    }

    // Preview is just a truncated version of the plaintext
    final preview = message.substring(0, message.length.clamp(0, 100));

    //encrypting the message
    final keyHelper = KeyHelper();
    final encryptionService = EncryptionService();
    final sharedKey = await keyHelper.deriveSharedKey(
      currentUserId,
      receiverId,
    );
    final encryptedMessage = await encryptionService.encryptMessage(
      message,
      sharedKey,
    );

    // create a new message
    Map<String, dynamic> newMessageMap = {
      'senderEmail': currentUserEmail,
      'receiverEmail': receiverEmail,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'ciphertext': encryptedMessage['ciphertext'],
      'nonce': encryptedMessage['nonce'],
      'mac': encryptedMessage['mac'],
      'timestamp': timestamp,
      'decryptedPreview': preview,
    };

    // construct chat room ID (sorted to ensure same ID for both users)
    List<String> emailIds = [currentUserEmail, receiverEmail];
    emailIds.sort(); // sort for consistent chat room ID
    String chatRoomId = emailIds.join("_");

    // add new message to database
    var messageDocRef = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessageMap);

    // Update the chat room document with participants array
    // (include both emails and UIDs for backward compatibility)
    await _firestore.collection("chat_rooms").doc(chatRoomId).set({
      'participants': [currentUserEmail, receiverEmail],
      'participantIds': [currentUserId, receiverId],
      'lastUpdated': timestamp,
    }, SetOptions(merge: true));

    return messageDocRef.id;
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userEmail, String otherUserEmail) {
    // construct chat room ID
    List<String> ids = [userEmail, otherUserEmail];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<String?> _getUidFromEmail(String email) async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('Users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.id;
    } catch (e) {
      print("Error getting UID from email: $e");
      return null;
    }
  }
}

// Message model
class Message {
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
  });

  // convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

class ChatUser {
  final String senderEmail;
  final String receiverEmail;
  final String lastMessage;
  final Timestamp timestamp;
  final String username;
  final String? profileImageUrl;

  ChatUser({
    required this.senderEmail,
    required this.receiverEmail,
    required this.lastMessage,
    required this.timestamp,
    required this.username,
    this.profileImageUrl,
  });
}
