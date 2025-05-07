import 'package:flutter/material.dart';
import 'package:chatty/models/group.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupTile extends StatelessWidget {
  final Group group;
  final void Function()? onTap;
  
  const GroupTile({
    Key? key,
    required this.group,
    this.onTap,
  }) : super(key: key);
  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();
    
    if (dateTime.year == now.year && 
        dateTime.month == now.month && 
        dateTime.day == now.day) {
      return DateFormat.jm().format(dateTime);
    } else if (dateTime.year == now.year &&
               dateTime.month == now.month &&
               dateTime.day == now.day - 1) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime); // Day name
    } else {
      return DateFormat('MMM d').format(dateTime); // Month & day
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.brightness == Brightness.light 
          ? Colors.white 
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            leading: Stack(
              children: [
                ProfileImage(
                  imageUrl: group.imageUrl,
                  fallbackText: group.name,
                  size: 52,
                  backgroundColor: theme.colorScheme.secondary,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.brightness == Brightness.light 
                            ? Colors.white 
                            : theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      group.memberCount.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              group.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: group.lastMessage != null 
                ? RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        if (group.lastMessageSender != null)
                          TextSpan(
                            text: '${group.lastMessageSender}: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        TextSpan(
                          text: group.lastMessage,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ) 
                : null,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (group.lastMessageTime != null)
                  Text(
                    _formatTimestamp(group.lastMessageTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}