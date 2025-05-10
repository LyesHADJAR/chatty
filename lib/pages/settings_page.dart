import 'package:chatty/components/profile_image.dart';
import 'package:chatty/models/chat_user.dart';
import 'package:chatty/pages/edit_profile_page.dart';
import 'package:chatty/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:chatty/services/auth/auth_service.dart';
import 'package:chatty/pages/change_password_page.dart';

class SettingsPage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      // Add a loading overlay when processing
      body: Stack(
        children: [
          FutureBuilder<ChattyUser?>(
            future: _authService.getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = snapshot.data;

              return ListView(
                children: [
                  // Profile section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap:
                              _isLoading
                                  ? null
                                  : () => _showProfileImageOptions(context),
                          child: Stack(
                            children: [
                              ProfileImage(
                                imageUrl: user?.profileImageUrl,
                                fallbackText:
                                    user?.username ?? user?.email ?? '',
                                size: 120,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          user?.username ?? '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Theme section
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Appearance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                          value: widget.isDarkMode,
                          onChanged:
                              _isLoading ? null : (_) => widget.toggleTheme(),
                          secondary: Icon(
                            widget.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account section
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 24,
                      bottom: 8,
                    ),
                    child: Text(
                      'Account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          enabled: !_isLoading,
                          onTap: () {
                            if (snapshot.data != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfilePage(user: snapshot.data!),
                                ),
                              );
                            }
                          },
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 70,
                          endIndent: 16,
                        ),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          enabled: !_isLoading,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ChangePasswordPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Sign out button with proper spacing
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // Add confirmation dialog for sign out
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Sign Out'),
                                        content: const Text(
                                          'Are you sure you want to sign out?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _authService.signOut();
                                            },
                                            child: const Text('Sign Out'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Show loading overlay when processing
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Update your existing _showProfileImageOptions method
  void _showProfileImageOptions(BuildContext context) {
    final storageService = StorageService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (dialogContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Change avatar color'),
                  onTap: () async {
                    // Close the modal first
                    Navigator.pop(dialogContext);

                    // Show loading
                    setState(() => _isLoading = true);

                    try {
                      // Just call uploadProfileImage without an actual file
                      // This will generate a new color
                      await storageService.uploadProfileImage(null);
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Avatar updated')),
                        );
                      }
                    } catch (e) {
                      print("Avatar update error: $e");
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to update avatar: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset to default avatar'),
                  onTap: () async {
                    // Close the modal first
                    Navigator.pop(dialogContext);

                    // Show loading
                    setState(() => _isLoading = true);

                    try {
                      await storageService.deleteProfileImage();
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Avatar reset to default'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Failed to reset avatar: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }
}
