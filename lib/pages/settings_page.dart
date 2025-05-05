import 'package:flutter/material.dart';
import 'package:chatty/services/auth/auth_service.dart';

class SettingsPage extends StatelessWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Theme section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Dark mode toggle
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Use dark theme throughout the app',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: isDarkMode,
                  onChanged: (_) => toggleTheme(),
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Account section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Edit Profile',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Change your profile information',
                    style: theme.textTheme.bodySmall,
                  ),
                  leading: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onBackground.withOpacity(0.5),
                  ),
                  onTap: () {
                    // Navigate to profile edit page
                  },
                ),
                Divider(height: 1, thickness: 1, indent: 70, endIndent: 16),
                ListTile(
                  title: Text(
                    'Change Password',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Update your password',
                    style: theme.textTheme.bodySmall,
                  ),
                  leading: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onBackground.withOpacity(0.5),
                  ),
                  onTap: () {
                    // Navigate to change password page
                  },
                ),
              ],
            ),
          ),
          
          // Notification section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Message Notifications',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Get notified about new messages',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: true,
                  onChanged: (value) {
                    // Toggle message notifications
                  },
                  secondary: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Sign out button with proper spacing
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextButton(
              onPressed: () {
                final AuthService authService = AuthService();
                authService.signOut();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // App version footer
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Chatty v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}