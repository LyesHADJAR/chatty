import 'package:chatty/components/attachment_bottom_sheet.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isCurrentUser ? 60 : 12,
        right: isCurrentUser ? 12 : 60,
      ),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
          bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          message.startsWith("[LINK]")
              ? LinkPreview(url: message.substring(6))
              : Text(
                message,
                style: TextStyle(
                  color:
                      isCurrentUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSecondary,
                  fontSize: 16,
                  height: 1.4,
                  fontFamily: 'Montserrat',
                ),
              ),
    );
  }
}
