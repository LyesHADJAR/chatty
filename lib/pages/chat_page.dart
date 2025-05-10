import 'package:chatty/components/chat_bubble.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:chatty/pages/contact_info_page.dart';
import 'package:chatty/services/crypto/encryption_service.dart';
import 'package:chatty/services/crypto/key_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatty/services/chat/chat_service.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String recieverEmail;
  final String? recieverUsername;
  final String? recieverProfileImageUrl;
  final Function toggleTheme;
  final bool isDarkMode;

  const ChatPage({
    super.key,
    required this.recieverEmail,
    this.recieverUsername,
    this.recieverProfileImageUrl,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && !_isSending) {
      setState(() {
        _isSending = true;
      });

      try {
        await _chatService.sendMessage(
          widget.recieverEmail,
          _messageController.text.trim(),
        );

        _messageController.clear();
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
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

  Future<String> _decryptMessage(Map<String, dynamic> data) async {
    try {
      final currentUserID = _auth.currentUser!.uid;
      final senderID = data['senderId'] ?? data['sender_id'];
      final receiverID = data['receiverId'] ?? data['receiver_id'];
      final otherUserId = currentUserID == senderID ? receiverID : senderID;

      final keyHelper = KeyHelper();
      final encryptionService = EncryptionService();

      final sharedKey = await keyHelper.deriveSharedKey(
        currentUserID,
        otherUserId,
      );

      return await encryptionService.decryptMessage({
        'ciphertext': data['ciphertext'],
        'nonce': data['nonce'],
        'mac': data['mac'],
      }, sharedKey);
    } catch (e) {
      print(' Decryption failed: $e');
      return '[Decryption failed]';
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileImage(
              imageUrl: widget.recieverProfileImageUrl,
              fallbackText: widget.recieverUsername ?? widget.recieverEmail,
              size: 36,
              backgroundColor: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.recieverUsername ?? widget.recieverEmail,
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              radius: 16,
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ContactInfoPage(
                        userEmail: widget.recieverEmail,
                        username: widget.recieverUsername,
                        profileImageUrl: widget.recieverProfileImageUrl,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(child: _buildMessageList()),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    final String currentUserEmail = _auth.currentUser!.email!;
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: _chatService.getMessages(currentUserEmail, widget.recieverEmail),
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

        // Scroll to bottom after building
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        final messages = snapshot.data!.docs;

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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
            final data = messages[index].data() as Map<String, dynamic>;

            return FutureBuilder(
              future: _decryptMessage(data),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final messageText = snapshot.data!;

                final timestamp = data['timestamp'] as Timestamp;
                final isCurrentUser = data['senderEmail'] == currentUserEmail;

                // Show timestamp for first message and when there's a significant time gap
                bool showTimestamp = index == 0;
                if (index > 0) {
                  final prevData =
                      messages[index - 1].data() as Map<String, dynamic>;
                  final prevTimestamp = prevData['timestamp'] as Timestamp;
                  final timeDiff = timestamp.seconds - prevTimestamp.seconds;
                  if (timeDiff > 300) {
                    showTimestamp = true;
                  }
                }

                return Column(
                  children: [
                    if (showTimestamp)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                            _formatTimestamp(timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment:
                          isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        ChatBubble(
                          message: messageText,
                          isCurrentUser: isCurrentUser,
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // build message input
  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
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
              onPressed: sendMessage,
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _messageController.text.isEmpty || _isSending
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
    );
  }
}
