import 'dart:convert';
import 'package:chatty/services/crypto/encryption_service.dart';
import 'package:chatty/services/crypto/key_helper.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/chat_bubble.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:chatty/services/chat/group_service.dart';
import 'package:chatty/models/group.dart';
import 'package:chatty/models/group_message.dart';
import 'package:chatty/pages/group_info_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;

  const GroupChatPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroupService _groupService = GroupService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSending = false;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _groupService.sendGroupMessage(
        widget.groupId,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<String> _decryptMessageForUser(GroupMessage encryptedMessage) async {
    try {
      //get the current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'Usre not logged in';

      final keyHelper = KeyHelper();
      final encryptionService = EncryptionService();

      //get the encrypted key of the current user
      final encryptedKeyData =
          encryptedMessage.encryptedKeys?[currentUser.email];
      if (encryptedKeyData == null) return 'Key not found';

      //derive the shared key between the sender and the current user (receiver)
      final sharedKey = await keyHelper.deriveSharedKey(
        currentUser.uid,
        encryptedMessage.senderId,
      );

      //decrypt the messageKey
      final decryptedKeyBase64 = await encryptionService.decryptMessage({
        'ciphertext': encryptedKeyData['key'],
        'nonce': encryptedKeyData['nonce'],
        'mac': encryptedKeyData['mac'],
      }, sharedKey);

      final messageKeyBytes = base64Decode(decryptedKeyBase64);
      final messageKey = SecretKey(messageKeyBytes);

      //decrypt the encrypted message using the message content
      final decryptedMessage = await encryptionService.decryptMessage({
        'ciphertext': encryptedMessage.ciphertext ?? '',
        'nonce': encryptedMessage.nonce ?? '',
        'mac': encryptedMessage.mac ?? '',
      }, messageKey);

      return decryptedMessage;
    } catch (e) {
      return 'Failed to decrypt';
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat.jm().format(dateTime);
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _auth.currentUser?.uid;

    return StreamBuilder<Group?>(
      stream: _groupService.getGroupById(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Failed to load group: ${snapshot.error ?? "Group not found"}',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }

        final group = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ProfileImage(
                  imageUrl: group.imageUrl,
                  fallbackText: group.name,
                  size: 36,
                  backgroundColor: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${group.members.length} members',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GroupInfoPage(groupId: widget.groupId),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<GroupMessage>>(
                  stream: _groupService.getGroupMessages(widget.groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    // Scroll to bottom after building
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Send a message to start chatting!",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser = message.senderId == currentUserId;

                        // Show timestamp for first message and when there's a significant time gap
                        bool showTimestamp = index == 0;
                        if (index > 0) {
                          final prevMessage = messages[index - 1];
                          final timeDiff =
                              message.timestamp.seconds -
                              prevMessage.timestamp.seconds;
                          if (timeDiff > 300) {
                            // 5 minutes
                            showTimestamp = true;
                          }
                        }

                        // Check if we need to show sender info
                        bool showSender =
                            !isCurrentUser &&
                            (index == 0 ||
                                index > 0 &&
                                    messages[index - 1].senderId !=
                                        message.senderId);

                        return Column(
                          crossAxisAlignment:
                              isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            if (showTimestamp)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatTimestamp(message.timestamp),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ),
                              ),

                            if (showSender && !isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 4,
                                ),
                                child: Text(
                                  message.senderName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),

                            Row(
                              mainAxisAlignment:
                                  isCurrentUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isCurrentUser && showSender)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ProfileImage(
                                      imageUrl: message.senderImageUrl,
                                      fallbackText: message.senderName,
                                      size: 30,
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                    ),
                                  )
                                else if (!isCurrentUser)
                                  const SizedBox(
                                    width: 38,
                                  ), // To align messages

                                Flexible(
                                  child: FutureBuilder<String>(
                                    future: _decryptMessageForUser(message),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 50,
                                          height: 20,
                                          child: LinearProgressIndicator(),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Text(
                                          "Error decrypting the messages",
                                        );
                                      }

                                      final decryptedMessage =
                                          snapshot.data ?? '';

                                      return ChatBubble(
                                        message: decryptedMessage,
                                        isCurrentUser: isCurrentUser,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Attachment button
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        onPressed: () {
                          // Future feature: attachments
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Attachments coming soon'),
                            ),
                          );
                        },
                      ),

                      // Text field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),

                      // Send button
                      IconButton(
                        onPressed: _sendMessage,
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                _messageController.text.trim().isEmpty ||
                                        _isSending
                                    ? Colors.grey.withOpacity(0.5)
                                    : theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child:
                              _isSending
                                  ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: theme.colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    Icons.send_rounded,
                                    color: theme.colorScheme.onPrimary,
                                    size: 16,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
