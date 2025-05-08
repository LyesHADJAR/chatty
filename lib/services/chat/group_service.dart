import 'dart:convert';
import 'package:chatty/services/crypto/encryption_service.dart';
import 'package:chatty/services/crypto/key_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/models/group.dart';
import 'package:chatty/models/group_message.dart';
import 'package:chatty/models/chat_user.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new group
  Future<Group> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Add current user to members if not already included
      if (!memberIds.contains(currentUser.uid)) {
        memberIds.add(currentUser.uid);
      }

      // Create group document
      final groupRef = _firestore.collection('groups').doc();
      final timestamp = Timestamp.now();

      final group = Group(
        id: groupRef.id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        createdBy: currentUser.uid,
        members: memberIds,
        admins: [currentUser.uid], // Creator is the first admin
        createdAt: timestamp,
      );

      await groupRef.set(group.toMap());

      // Add group reference to each member's user document
      for (final memberId in memberIds) {
        await _firestore.collection('Users').doc(memberId).update({
          'groups': FieldValue.arrayUnion([groupRef.id]),
        });
      }

      return group;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Get all groups the current user is a member of
  Stream<List<Group>> getUserGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Remove the orderBy which requires the index
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final groups =
              snapshot.docs.map((doc) {
                return Group.fromMap(doc.data(), doc.id);
              }).toList();

          // Sort in-memory instead of in the query
          groups.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) {
              return 0;
            } else if (a.lastMessageTime == null) {
              return 1; // Put null timestamps at the end
            } else if (b.lastMessageTime == null) {
              return -1;
            } else {
              return b.lastMessageTime!.compareTo(a.lastMessageTime!);
            }
          });

          return groups;
        });
  }

  // Get a specific group by ID
  Stream<Group?> getGroupById(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Group.fromMap(doc.data()!, doc.id);
    });
  }

  // Get all messages for a group (continued)
  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GroupMessage.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Send a message to a group
  Future<void> sendGroupMessage(String groupId, String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get current user's details
      final userDoc =
          await _firestore.collection('Users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data not found');
      }
      final username = userData['username'] ?? currentUser.email;
      final userImageUrl = userData['profileImageUrl'];
      final timestamp = Timestamp.now();

      //get th memebers of the group
      final groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final List<dynamic> memberIDS = groupData['members'] ?? [];

      //generating the random symmetric key to encrypt the message
      final encryptionService = EncryptionService();
      final messageKey = await encryptionService.generateRandomKey();
      final messageKeyBytes = await messageKey.extractBytes();

      //encrypt the message using this symmetric key
      final encryptedMessage = await encryptionService.encryptMessage(
        message,
        messageKey,
      );

      //for each member in the group, encrypt the messageKey using the shared key (between that member and the current user)
      final keyHelper = KeyHelper();
      Map<String, dynamic> encryptedKeys = {};

      for (String memberId in memberIDS) {
        final sharedKey = await keyHelper.deriveSharedKey(
          currentUser.uid,
          memberId,
        );

        final encryptedKeyData = await encryptionService.encryptMessage(
          base64Encode(messageKeyBytes),
          sharedKey,
        );

        final memberDoc =
            await _firestore.collection('Users').doc(memberId).get();
        final memberEmail = memberDoc.data()?['email'];
        if (memberEmail != null) {
          encryptedKeys[memberEmail.toString().toLowerCase()] = {
            'key': encryptedKeyData['ciphertext'],
            'nonce': encryptedKeyData['nonce'],
            'mac': encryptedKeyData['mac'],
          };
        }
      }

      // Create new message with the encrypted data
      final newMessage = {
        'groupId': groupId,
        'ciphertext': encryptedMessage['ciphertext'],
        'nonce': encryptedMessage['nonce'],
        'mac': encryptedMessage['mac'],
        'encryptedKeys': encryptedKeys,
        'senderId': currentUser.uid,
        'senderName': username,
        'timestamp': timestamp,
        'senderImageUrl': userImageUrl,
      };

      // Add message to group's messages collection
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(newMessage);

      // Update group's last message info
      await _firestore.collection('groups').doc(groupId).update({
        'lastMessage': message.substring(0, message.length.clamp(0, 100)),
        'lastMessageTime': timestamp,
        'lastMessageSender': username,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Add members to a group
  Future<void> addMembersToGroup(String groupId, List<String> memberIds) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if current user is an admin of the group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);
      if (!group.isUserAdmin(currentUser.uid)) {
        throw Exception('You must be an admin to add members');
      }

      // Add members to group
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion(memberIds),
      });

      // Add group reference to each member's user document
      for (final memberId in memberIds) {
        await _firestore.collection('Users').doc(memberId).update({
          'groups': FieldValue.arrayUnion([groupId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  // Remove a member from a group
  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if current user is an admin or the member being removed is the current user
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);
      if (!group.isUserAdmin(currentUser.uid) && memberId != currentUser.uid) {
        throw Exception('You must be an admin to remove members');
      }

      // If removing an admin, check if it's not the last admin
      if (group.admins.contains(memberId)) {
        if (group.admins.length <= 1) {
          throw Exception('Cannot remove the last admin from the group');
        }

        // Remove admin status
        await _firestore.collection('groups').doc(groupId).update({
          'admins': FieldValue.arrayRemove([memberId]),
        });
      }

      // Remove member from group
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });

      // Remove group reference from user's document
      await _firestore.collection('Users').doc(memberId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });

      // If no members left, delete the group
      if (group.members.length <= 1) {
        await _firestore.collection('groups').doc(groupId).delete();
      }
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Make a user an admin
  Future<void> makeUserAdmin(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if current user is an admin
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);
      if (!group.isUserAdmin(currentUser.uid)) {
        throw Exception('You must be an admin to assign admin rights');
      }

      // Check if the user is a member of the group
      if (!group.members.contains(userId)) {
        throw Exception('User is not a member of this group');
      }

      // Make user an admin
      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to make user an admin: $e');
    }
  }

  // Remove admin status from a user
  Future<void> removeAdminStatus(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if current user is an admin
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);
      if (!group.isUserAdmin(currentUser.uid)) {
        throw Exception('You must be an admin to remove admin rights');
      }

      // Check if not removing the last admin
      if (group.admins.length <= 1 && group.admins.contains(userId)) {
        throw Exception('Cannot remove the last admin from the group');
      }

      // Remove admin status
      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to remove admin status: $e');
    }
  }

  // Update group info (name, description, image)
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if current user is an admin
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);
      if (!group.isUserAdmin(currentUser.uid)) {
        throw Exception('You must be an admin to update group info');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};
      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      // Update group info
      if (updateData.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update group info: $e');
    }
  }

  // Get all users not in a specific group (for adding members)
  Future<List<ChattyUser>> getUsersNotInGroup(String groupId) async {
    try {
      // Get the group to get current members
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupData, groupId);

      // Get all users
      final usersSnapshot = await _firestore.collection('Users').get();

      // Filter out users already in the group
      return usersSnapshot.docs
          .where((doc) => !group.members.contains(doc.id))
          .map((doc) => ChattyUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users not in group: $e');
    }
  }
}
