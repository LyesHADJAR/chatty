import 'package:flutter/material.dart';
import 'package:chatty/components/button.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactInfoPage extends StatelessWidget {
  final String userEmail;
  final String? username;
  final String? profileImageUrl;

  const ContactInfoPage({
    Key? key,
    required this.userEmail,
    this.username,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Info'),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: FirebaseFirestore.instance
            .collection('Users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty ? 
                FirebaseFirestore.instance.collection('Users').doc(snapshot.docs.first.id).get() : null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final displayName = userData?['username'] ?? username ?? userEmail;
          final imageUrl = userData?['profileImageUrl'] ?? profileImageUrl;
          final isCurrentUser = FirebaseAuth.instance.currentUser?.email == userEmail;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image
                Center(
                  child: ProfileImage(
                    imageUrl: imageUrl,
                    fallbackText: displayName,
                    size: 120,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Name
                Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Text(
                  userEmail,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Info sections
                _buildInfoSection(
                  context, 
                  'Account Information',
                  [
                    {'label': 'Username', 'value': displayName},
                    {'label': 'Email', 'value': userEmail},
                    {'label': 'Account Status', 'value': 'Active'},
                  ]
                ),
                
                const SizedBox(height: 24),
                
                if (!isCurrentUser)
                  CustomButton(
                    text: 'Block User',
                    isOutlined: true,
                    prefixIcon: const Icon(Icons.block, size: 20),
                    onTap: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Block User'),
                          content: Text('Are you sure you want to block $displayName?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Implement blocking functionality
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$displayName has been blocked')),
                                );
                              },
                              child: const Text('Block'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildInfoSection(BuildContext context, String title, List<Map<String, String>> items) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['label'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  item['value'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}