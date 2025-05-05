import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? subtitle;
  final void Function()? onTap;
  final bool isNewContact;
  final Timestamp? lastMessageTime;
  
  const UserTile({
    super.key,
    required this.text,
    this.subtitle,
    this.onTap,
    this.isNewContact = false,
    this.lastMessageTime,
  });
  
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
            leading: CircleAvatar(
              backgroundColor: isNewContact 
                  ? theme.colorScheme.secondary 
                  : theme.colorScheme.primary,
              radius: 26,
              child: Text(
                text.isNotEmpty ? text.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: isNewContact 
                      ? theme.colorScheme.onSecondary 
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            title: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle != null 
                ? Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ) 
                : null,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageTime != null)
                  Text(
                    _formatTimestamp(lastMessageTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}