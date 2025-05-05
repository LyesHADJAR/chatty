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
  Stream<List<ChatUser>> getChatUsers() {
    final currentUserEmail = _auth.currentUser?.email;
    if (currentUserEmail == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection("chat_rooms")
        .where('participants', arrayContains: currentUserEmail)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChatUser> chatUsers = [];
          
          for (var doc in snapshot.docs) {
            String chatRoomId = doc.id;
            List<String> emails = chatRoomId.split('_');
            
            if (emails.length == 2) {
              
              // Get the latest message for this chat
              QuerySnapshot messagesSnapshot = await _firestore
                  .collection("chat_rooms")
                  .doc(chatRoomId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .limit(1)
                  .get();
              
              String lastMessage = "";
              Timestamp? timestamp;
              
              if (messagesSnapshot.docs.isNotEmpty) {
                var messageData = messagesSnapshot.docs.first.data() as Map<String, dynamic>;
                lastMessage = messageData['message'] ?? "";
                timestamp = messageData['timestamp'] as Timestamp?;
              }
              
              chatUsers.add(ChatUser(
                senderEmail: emails[0],
                receiverEmail: emails[1],
                lastMessage: lastMessage,
                timestamp: timestamp ?? Timestamp.now(),
              ));
            }
          }
          
          // Sort by most recent message
          chatUsers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return chatUsers;
        });
  }

  // SEND MESSAGE
  Future<void> sendMessage(String receiverEmail, String message) async {
    // get current user info
    final String currentUserEmail = currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderEmail: currentUserEmail,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID (sorted to ensure same ID for both users)
    List<String> ids = [currentUserEmail, receiverEmail];
    ids.sort(); // sort the ids to ensure same chatroom ID regardless of who sends message
    String chatRoomId = ids.join("_");

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
        
    // Update the chat room document with participants array
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .set({
          'participants': [currentUserEmail, receiverEmail],
          'lastUpdated': timestamp,
        }, SetOptions(merge: true));
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

// ChatUser model for displaying in the chat list
class ChatUser {
  final String senderEmail;
  final String receiverEmail;
  final String lastMessage;
  final Timestamp timestamp;
  
  ChatUser({
    required this.senderEmail,
    required this.receiverEmail,
    required this.lastMessage,
    required this.timestamp,
  });
}